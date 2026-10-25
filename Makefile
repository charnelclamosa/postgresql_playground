# ---- Configuration ----
PROJECT_NAME     ?= myapp
COMPOSE          ?= docker compose
COMPOSE_FILE     ?= docker-compose.yaml
PYTHON_SERVICE  ?= python
DB_SERVICE			 ?= db
API_PORT         ?= 8080
SERVICE          ?=
FILE             ?=

# Passed through to docker-compose.yaml
export API_PORT

COMPOSE_CMD := $(COMPOSE) -p $(PROJECT_NAME) -f $(COMPOSE_FILE)

.PHONY: all build run logs python-shell python-cli stop clean init-db connect-db run-solution

all: build run

## Build the Docker images for all services
# Usage:
# $ make build
# $ make build SERVICE=python
build:
	$(COMPOSE_CMD) build $(SERVICE)

## Run the dev stack with hot reload (Vite dev server + uvicorn --reload (Falcon), detached)
# Usage:
# $ make run
# $ make run API_PORT=9000
run: .init-db
	$(COMPOSE_CMD) up -d --build
	@echo "API: http://localhost:$(API_PORT)/api/healthz"

## Stop and remove containers and networks
stop:
	$(COMPOSE_CMD) down --remove-orphans

.init-db:
	@$(COMPOSE_CMD) up -d --wait $(DB_SERVICE)
	@$(COMPOSE_CMD) exec -T $(DB_SERVICE) bash /app/bin/init_db.sh
	@$(COMPOSE_CMD) stop $(DB_SERVICE)
	@touch .init-db

init-db: .init-db

reset-db:
	$(COMPOSE_CMD) build $(DB_SERVICE)
	rm -f .init-db
	$(MAKE) .init-db

wipe-db:
	$(COMPOSE_CMD) stop $(DB_SERVICE)
	$(COMPOSE_CMD) run --rm --no-deps --entrypoint bash $(DB_SERVICE) -c 'find /var/lib/postgresql/data -mindepth 1 -delete'
	rm -f .init-db

connect-db:
	$(COMPOSE_CMD) exec $(DB_SERVICE) bash -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

## Run one SQL file from db/sql/solutions and print its result in the terminal
# Usage:
# $ make run-solution FILE=04_sessionization.sql
run-solution:
	@test -n "$(FILE)" || { echo "Usage: make run-solution FILE=<name>.sql"; exit 1; }
	@$(COMPOSE_CMD) up -d --wait $(DB_SERVICE)
	@$(COMPOSE_CMD) exec -T $(DB_SERVICE) bash -c \
		'[ -f "$$1" ] || { echo "Not found: $$1"; exit 1; }; \
		 psql -q -U "$$POSTGRES_USER" -d "$$POSTGRES_DB" -v ON_ERROR_STOP=1 -f "$$1"' \
		_ /app/sql/solutions/$(FILE)

## Stream logs from the running containers
# Usage:
# $ make logs
# $ make logs SERVICE=python
logs:
	$(COMPOSE_CMD) logs -f $(SERVICE)

## Enter a shell inside the running python container
python-shell:
	$(COMPOSE_CMD) exec $(PYTHON_SERVICE) bash || $(COMPOSE_CMD) exec $(PYTHON_SERVICE) sh

## Enter a Python CLI inside a new python container
python-cli:
	$(COMPOSE_CMD) run --rm --no-deps --entrypoint python $(PYTHON_SERVICE)

## Remove containers, networks, volumes, and locally built images
clean:
	$(COMPOSE_CMD) down -v --remove-orphans --rmi local