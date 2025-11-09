package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/codity/code-review-gateway/go-gateway/auth"
	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"golang.org/x/time/rate"
)

var (
	rdb         *redis.Client
	rateLimiter *rate.Limiter
	ctx         = context.Background()
)

type RateLimitMiddleware struct {
	limiter *rate.Limiter
}

func NewRateLimitMiddleware(rps float64, burst int) *RateLimitMiddleware {
	return &RateLimitMiddleware{
		limiter: rate.NewLimiter(rate.Limit(rps), burst),
	}
}

func (rl *RateLimitMiddleware) Handler() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !rl.limiter.Allow() {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "Rate limit exceeded",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

func getCachedResponse(c *gin.Context, key string) (bool, string) {
	val, err := rdb.Get(ctx, key).Result()
	if err == redis.Nil {
		return false, ""
	}
	if err != nil {
		return false, ""
	}
	return true, val
}

func cacheResponse(key string, value string, ttl time.Duration) {
	rdb.Set(ctx, key, value, ttl)
}

func cacheMiddleware(ttl time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		cacheKey := fmt.Sprintf("cache:%s:%s", c.Request.Method, c.Request.URL.Path)

		if cached, value := getCachedResponse(c, cacheKey); cached {
			c.Header("X-Cache", "HIT")
			c.Data(http.StatusOK, "application/json", []byte(value))
			c.Abort()
			return
		}

		c.Header("X-Cache", "MISS")
		c.Next()
	}
}

func proxyToRubyAPI(c *gin.Context) {
	rubyAPIURL := os.Getenv("RUBY_API_URL")
	if rubyAPIURL == "" {
		rubyAPIURL = "http://localhost:3000"
	}

	client := &http.Client{Timeout: 10 * time.Second}
	req, err := http.NewRequest(c.Request.Method, rubyAPIURL+c.Request.URL.Path, c.Request.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create request"})
		return
	}

	req.Header = c.Request.Header.Clone()
	req.Header.Set("X-Forwarded-For", c.ClientIP())

	resp, err := client.Do(req)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "Ruby API unavailable"})
		return
	}
	defer resp.Body.Close()

	for k, v := range resp.Header {
		c.Header(k, v[0])
	}

	cacheKey := fmt.Sprintf("cache:%s:%s", c.Request.Method, c.Request.URL.Path)
	if resp.StatusCode == http.StatusOK && c.Request.Method == "GET" {
		bodyBytes := make([]byte, 0)
		resp.Body.Read(bodyBytes)
		cacheResponse(cacheKey, string(bodyBytes), 5*time.Minute)
	}

	c.DataFromReader(resp.StatusCode, resp.Header.Get("Content-Type"), resp.Body, nil)
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "go-gateway",
		"time":    time.Now().Unix(),
	})
}

func handleLogin(c *gin.Context) {
	var loginReq struct {
		Email    string `json:"email" binding:"required"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&loginReq); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	rubyAPIURL := os.Getenv("RUBY_API_URL")
	if rubyAPIURL == "" {
		rubyAPIURL = "http://localhost:3000"
	}

	bodyBytes, _ := c.GetRawData()
	client := &http.Client{Timeout: 10 * time.Second}
	req, _ := http.NewRequest("POST", rubyAPIURL+"/api/v1/auth/login", bytes.NewBuffer(bodyBytes))
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "Ruby API unavailable"})
		return
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		c.Data(resp.StatusCode, resp.Header.Get("Content-Type"), body)
		return
	}

	var userResp struct {
		User struct {
			ID    int    `json:"id"`
			Email string `json:"email"`
		} `json:"user"`
	}

	if err := json.Unmarshal(body, &userResp); err == nil && userResp.User.ID > 0 {
		tokenPair, err := auth.GenerateTokenPair(userResp.User.ID, userResp.User.Email)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate tokens"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"user":          userResp.User,
			"access_token":  tokenPair.AccessToken,
			"refresh_token": tokenPair.RefreshToken,
			"expires_in":    tokenPair.ExpiresIn,
		})
		return
	}

	c.Data(resp.StatusCode, resp.Header.Get("Content-Type"), body)
}

func handleRefresh(c *gin.Context) {
	var refreshReq struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}

	if err := c.ShouldBindJSON(&refreshReq); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	tokenPair, err := auth.RefreshAccessToken(refreshReq.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid refresh token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"access_token":  tokenPair.AccessToken,
		"refresh_token": tokenPair.RefreshToken,
		"expires_in":    tokenPair.ExpiresIn,
	})
}

func handleValidate(c *gin.Context) {
	userID, _ := c.Get("user_id")
	email, _ := c.Get("user_email")

	c.JSON(http.StatusOK, gin.H{
		"valid": true,
		"user": gin.H{
			"id":    userID,
			"email": email,
		},
	})
}

func main() {
	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		redisURL = "localhost:6379"
	}

	rdb = redis.NewClient(&redis.Options{
		Addr:     redisURL,
		Password: "",
		DB:       0,
	})

	if err := rdb.Ping(ctx).Err(); err != nil {
		log.Printf("Warning: Redis connection failed: %v", err)
	}

	rateLimiter = NewRateLimitMiddleware(100.0, 200)

	if os.Getenv("GIN_MODE") == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.Default()

	r.Use(rateLimiter.Handler())
	r.Use(cacheMiddleware(5 * time.Minute))

	r.GET("/health", healthCheck)

	authRoutes := r.Group("/api/v1/auth")
	{
		authRoutes.POST("/login", handleLogin)
		authRoutes.POST("/refresh", handleRefresh)
		authRoutes.POST("/validate", auth.AuthMiddleware(), handleValidate)
	}

	apiRoutes := r.Group("/api/v1")
	apiRoutes.Use(auth.AuthMiddleware())
	{
		apiRoutes.GET("/*path", cacheMiddleware(5*time.Minute), proxyToRubyAPI)
		apiRoutes.POST("/*path", proxyToRubyAPI)
		apiRoutes.PUT("/*path", proxyToRubyAPI)
		apiRoutes.DELETE("/*path", proxyToRubyAPI)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Gateway server starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
