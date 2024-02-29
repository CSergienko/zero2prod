set export := true
set dotenv-load := true
set positional-arguments := true

init:
  cargo install cargo-tarpaulin
  cargo install cargo-watch
  cargo install cargo-expand
  cargo install cargo-udeps
  cargo install sqlx-cli -F rustls,postgres
  rustup component add clippy
  rustup component add rustfmt

dev:
  cargo watch -x clippy -x test -x run

lint:
  cargo clippy

test:
  cargo test

format:
  cargo fmt

format_check:
  cargo fmt -- --check

audit:
  cargo audit

quality_checks: lint format_check
  cargo sqlx prepare --workspace --check

collect_coverage:
  cargo tarpaulin --ignore-tests

[private]
db_container_start:
  #!/usr/bin/env bash
  set -x
  set -eo pipefail

  if ! [ -x "$(command -v psql)" ]; then
    echo >&2 "Error: psql is not installed."
    exit 1
  fi

  if [[ -z "${SKIP_DOCKER}" ]]
  then
    docker run \
      -e POSTGRES_USER=${DB_USER} \
      -e POSTGRES_PASSWORD=${DB_PASSWORD} \
      -e POSTGRES_DB=${DB_NAME} \
      -p "${DB_PORT}":5432 \
      -d postgres \
      postgres -N 1000
  fi

  # keep pinging postgres until it's ready to accept commands
  export PGPASSWORD="${DB_PASSWORD}"
  until psql -h "${DB_HOST}" -U "${DB_USER}" -p "${DB_PORT}" -d "postgres" -c '\q'; do
    >&2 echo "Postgres is still unavailable - sleeping"
    sleep 1
  done

  >&2 echo "Postgres is up and running on port ${DB_PORT}"

[private]
db_create:
  #!/usr/bin/env bash
  set -x
  set -eo pipefail

  if ! [ -x "$(command -v sqlx)" ]; then
    echo >&2 "Error: sqlx is not installed."
    exit 1
  fi

  sqlx database create
  sqlx migrate run


db_init: db_container_start db_create db_prepare

db_migrate *args='run':
  sqlx migrate $@
  just db_prepare

db_prepare:
  cargo sqlx prepare --workspace

db *args:
  sqlx $@

docker_build:
  docker build --tag zero2prod --file Dockerfile .
