# Makefile for local development commands

# -----------------------------------------------------------------------------
# Variables (you can override when invoking e.g. `make DB_PORT=5433 db-up`)
# -----------------------------------------------------------------------------
IMAGE_NAME ?= highstreet-postgres
CONTAINER_NAME ?= highstreet-db
DB_PORT ?= 5432

# -----------------------------------------------------------------------------
# Docker helpers
# -----------------------------------------------------------------------------

.PHONY: db-build db-up db-down db-logs

# Build the Postgres image from the Dockerfile in the repo root
# -----------------------------------------------------------------------------
db-build:
	docker build -t $(IMAGE_NAME) .

# Run the container in detached mode, mapping the port to the host
# -----------------------------------------------------------------------------
db-up: db-build
	docker run -d --name $(CONTAINER_NAME) \
	  -e POSTGRES_USER=postgres \
	  -e POSTGRES_PASSWORD=postgres \
	  -e POSTGRES_DB=highstreet \
	  -p $(DB_PORT):5432 \
	  $(IMAGE_NAME)
	@echo "🚀 Postgres is starting on port $(DB_PORT). Use 'make db-logs' to tail logs."

# Stop & remove the running container (if any)
# -----------------------------------------------------------------------------
db-down:
	-@docker rm -f $(CONTAINER_NAME) 2>/dev/null || true
	@echo "🧹 Postgres container removed."

# Tail the Postgres logs (Ctrl-C to stop following)
# -----------------------------------------------------------------------------
db-logs:
	docker logs -f $(CONTAINER_NAME)
