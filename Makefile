.PHONY: help setup-go setup-ruby test-go test-ruby test-all build-go run-go run-ruby clean

help:
	@echo "Code Review Gateway - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  setup-go      - Install Go dependencies"
	@echo "  setup-ruby    - Install Ruby dependencies"
	@echo "  test-go       - Run Go tests"
	@echo "  test-ruby     - Run Ruby tests"
	@echo "  test-all      - Run all tests"
	@echo "  build-go      - Build Go gateway"
	@echo "  run-go        - Run Go gateway"
	@echo "  run-ruby      - Run Ruby API"
	@echo "  clean         - Clean build artifacts"

setup-go:
	cd go-gateway && go mod download

setup-ruby:
	cd ruby-api && bundle install

test-go:
	cd go-gateway && go test -v ./...

test-ruby:
	cd ruby-api && bundle exec rspec

test-all: test-go test-ruby

build-go:
	cd go-gateway && go build -o gateway .

run-go:
	cd go-gateway && go run main.go

run-ruby:
	cd ruby-api && bundle exec rails server

clean:
	rm -f go-gateway/gateway
	rm -f go-gateway/coverage.txt

