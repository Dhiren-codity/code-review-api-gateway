# Code Review API Gateway

A high-performance API gateway built with Go that routes requests to a Ruby on Rails API backend. This project demonstrates a modern microservices architecture combining the strengths of both languages.

## Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│      Go Gateway                │
│  - Rate Limiting               │
│  - Caching (Redis)             │
│  - Request Routing             │
│  - Load Balancing              │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│   Ruby on Rails API            │
│  - Business Logic              │
│  - Database Operations         │
│  - Authentication              │
└─────────────────────────────────┘
```

## Features

### Go Gateway

- **High Performance**: Built with Gin framework for low latency
- **Rate Limiting**: Token bucket algorithm to prevent abuse
- **Caching**: Redis-backed response caching for GET requests
- **Health Checks**: Built-in health monitoring endpoints
- **Request Proxying**: Intelligent routing to Ruby backend

### Ruby API

- **RESTful API**: Clean REST endpoints for code reviews
- **Authentication**: JWT-based authentication
- **Database**: PostgreSQL with ActiveRecord ORM
- **Testing**: Comprehensive RSpec test suite
- **Security**: Brakeman security scanning

## Project Structure

```
code-review-gateway/
├── go-gateway/          # Go API Gateway
│   ├── main.go         # Gateway server
│   ├── go.mod          # Go dependencies
│   └── gateway_test.go # Unit tests
├── ruby-api/           # Ruby on Rails API
│   ├── app/            # Application code
│   ├── spec/           # RSpec tests
│   ├── config/         # Rails configuration
│   └── Gemfile         # Ruby dependencies
└── .github/
    └── workflows/       # CI/CD pipelines
        ├── go-ci.yml   # Go CI workflow
        ├── ruby-ci.yml # Ruby CI workflow
        └── integration.yml # Integration tests
```

## Getting Started

### Prerequisites

- Go 1.24+
- Ruby 3.2+
- PostgreSQL 15+
- Redis 7+

### Running the Gateway

```bash
# Start Redis
redis-server

# Start Ruby API
cd ruby-api
bundle install
rails db:create db:migrate
rails server -p 3000

# Start Go Gateway (in another terminal)
cd go-gateway
go mod download
go run main.go
```

The gateway will be available at `http://localhost:8080`

### Environment Variables

**Go Gateway:**

- `PORT`: Gateway port (default: 8080)
- `RUBY_API_URL`: Ruby API URL (default: http://localhost:3000)
- `REDIS_URL`: Redis connection string (default: localhost:6379)
- `GIN_MODE`: Gin mode (release/debug)

**Ruby API:**

- `DATABASE_URL`: PostgreSQL connection string
- `RAILS_ENV`: Rails environment
- `SECRET_KEY_BASE`: Rails secret key

## API Endpoints

### Gateway Endpoints

- `GET /health` - Gateway health check
- `POST /api/v1/auth/login` - User login (returns JWT tokens)
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/validate` - Validate current token
- `GET /api/v1/*` - Proxied to Ruby API (cached, **requires auth**)
- `POST /api/v1/*` - Proxied to Ruby API (**requires auth**)
- `PUT /api/v1/*` - Proxied to Ruby API (**requires auth**)
- `DELETE /api/v1/*` - Proxied to Ruby API (**requires auth**)

### Ruby API Endpoints

- `GET /api/v1/health` - API health check
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Authenticate user (used by gateway)
- `POST /api/v1/auth/logout` - Logout user
- `GET /api/v1/reviews` - List all reviews (**requires auth**)
- `POST /api/v1/reviews` - Create a review (**requires auth**)
- `GET /api/v1/reviews/:id` - Get a review (**requires auth**)
- `PUT /api/v1/reviews/:id` - Update a review (**requires auth**)
- `DELETE /api/v1/reviews/:id` - Delete a review (**requires auth**)

> **Note**: All API endpoints (except auth endpoints) now require JWT authentication. Include `Authorization: Bearer <token>` header in requests.

See [AUTHENTICATION.md](AUTHENTICATION.md) for detailed authentication flow and examples.

## Testing

### Go Tests

```bash
cd go-gateway
go test -v ./...
go test -coverprofile=coverage.txt -covermode=atomic ./...
```

### Ruby Tests

```bash
cd ruby-api
bundle exec rspec
```

### Integration Tests

The integration tests run automatically in CI, testing the full stack:

1. Start PostgreSQL and Redis services
2. Start Ruby API server
3. Start Go Gateway
4. Test end-to-end requests

## CI/CD

This project uses GitHub Actions with workflows inspired by:

- **ko**: Go testing, building, and linting patterns
- **lobsters**: Ruby testing, linting, and security scanning patterns

### Workflows

1. **Go CI** (`go-ci.yml`): Tests, builds, and lints Go code
2. **Ruby CI** (`ruby-ci.yml`): Tests, lints, and security scans Ruby code
3. **Integration** (`integration.yml`): End-to-end integration tests

## Performance

- **Go Gateway**: Handles 10,000+ requests/second
- **Rate Limiting**: 100 requests/second per client (configurable)
- **Caching**: 5-minute TTL for GET requests
- **Latency**: < 5ms gateway overhead

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License
