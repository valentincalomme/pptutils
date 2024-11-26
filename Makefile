#---------------------------------------- Setup ---------------------------------------#
include .env

SRC_DIR := src/
TESTS_DIR := tests/

MODULES := ${SRC_DIR} ${TESTS_DIR}
PYTHON_VERSIONS := 11 12 13

# Alias to run a command with uv and a specific python version
UV_RUN = VIRTUAL_ENV=".3${PYTHON_VERSION}.venv" \
	UV_PROJECT_ENVIRONMENT=".3${PYTHON_VERSION}.venv" \
	uv run --python 3.${PYTHON_VERSION}

# Required .PHONY targets
.PHONY: all clean

#-------------------------------- Installation scripts --------------------------------#

.PHONY: init install build publish lock upgrade

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

# Publish the package
publish:
	UV_PUBLISH_TOKEN=${UV_PUBLISH_TOKEN} uv publish

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

.PHONY: ci fix qa test test-version docs

# Run ci for all python versions
ci:
	make build
	@$(foreach v, $(PYTHON_VERSIONS), $(MAKE) qa-version PYTHON_VERSION=$(v) || exit 1;)
	@$(foreach v, $(PYTHON_VERSIONS), $(MAKE) test-version PYTHON_VERSION=$(v) || exit 1;)
	make docs

# Run qa for all python versions
qa:
	@$(foreach v, $(PYTHON_VERSIONS), $(MAKE) qa-version PYTHON_VERSION=$(v) || exit 1;)

# Run test for all support python versions
test:
	@$(foreach v, $(PYTHON_VERSIONS), $(MAKE) test-version PYTHON_VERSION=$(v) || exit 1;)
	@uv run coverage combine
	@uv run coverage report

# Code quality checks
qa-version:
	@${UV_RUN} ruff check --no-fix --preview ${MODULES}
	@${UV_RUN} mypy --incremental ${MODULES}
	@${UV_RUN} pyright

# Run tests (including doctests) and compute coverage
test-version:
	@${UV_RUN} pytest --cov=${SRC_DIR} --doctest-modules --cov-report=html
	@mv .coverage .coverage.3${PYTHON_VERSION}

# Build the documentation and break on any warnings/errors
docs:
	@uv run mkdocs build --strict

# Fixes issues in the codebase
fix:
	@uv run ruff check ${MODULES} --fix --preview
	@uv run ruff format ${MODULES}
