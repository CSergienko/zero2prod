init:
  cargo install cargo-tarpaulin
  cargo install cargo-watch
  cargo install cargo-expand
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

quality_checks: lint format_check audit

collect_coverage:
  cargo tarpaulin --ignore-tests
