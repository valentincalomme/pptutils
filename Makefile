#---------------------------------------- Setup ---------------------------------------#

SRC_DIR = src/
TESTS_DIR = tests/

MODULES = ${SRC_DIR} ${TESTS_DIR}

# Required .PHONY targets
.PHONY: all clean

#-------------------------------- Installation scripts --------------------------------#

.PHONY: init install build lock upgrade

# Run this command to setup the project
init: lock install install-pre-commit build

# Installs main and dev dependencies
install:
	uv sync --all-extras --dev --locked

# Install pre-commit hooks
install-pre-commit:
	uv run pre-commit install --install-hooks

# Build the package
build:
	uv build

# Lock the dependency versions
lock:
	uv lock

# Upgrade all dependencies given the dependency constraints
upgrade:
	uv lock --upgrade
	make install
	@if ! git diff --exit-code --quiet uv.lock; then \
		uv run pre-commit autoupdate; \
		fi

#------------------------------------- CI scripts -------------------------------------#

.PHONY: ci fix qa test docs

# Run a local CI pipeline
ci: build qa docs test build

# Code quality checks
qa:
	uv run ruff check --no-fix --preview ${MODULES}
	uv run mypy --incremental ${MODULES}
	uv run pyright

# Run tests (including doctests) and compute coverage
test:
	uv run pytest --cov=${SRC_DIR} --doctest-modules --cov-report=html

# Build the documentation and break on any warnings/errors
docs:
	uv run mkdocs build --strict

# Fixes issues in the codebase
fix:
	uv run ruff check ${MODULES} --fix --preview
	uv run ruff format ${MODULES}
