###############################################################################
# YouTube-Downloader – Makefile
###############################################################################
# make run            → local venv run
# make docker-run     → build (if needed) + launch container
# make deps-update    → regenerate requirements.{in,txt}
# make clean          → wipe venv, logs, docker image
# make help           → all targets
###############################################################################

# ── paths ──────────────────────────────────────────────────────────────────
VENV_DIR        := .venv
PYTHON          := python3
PIP             := $(VENV_DIR)/bin/pip
PYTHON_BIN      := $(VENV_DIR)/bin/python
REQUIREMENTS    := requirements.txt
REQUIREMENTS_IN := requirements.in
DEPS_OK_FILE    := $(VENV_DIR)/.deps-ok
APP             := main.py

IMAGE_NAME      := youtube-downloader
HOST_DIR        ?= $(HOME)/Downloads
CONTAINER_DIR   := /app

# ── phony targets ──────────────────────────────────────────────────────────
.PHONY: all install help venv deps deps-update check_ffmpeg check_deno run docker-build docker-run clean

all: run ## Default — alias for `make run`

install: deps check_ffmpeg check_deno ## Create venv, install deps, check ffmpeg & deno

# ── virtual env & deps ─────────────────────────────────────────────────────
$(VENV_DIR):
	@python3 -m venv $@ >/dev/null

venv: $(VENV_DIR) ## Create virtual environment

$(DEPS_OK_FILE): $(REQUIREMENTS) | venv
	@printf "Installing Python packages...\n"
	@$(PIP) install --quiet --upgrade pip >/dev/null
	@$(PIP) install --quiet -r $(REQUIREMENTS) >/dev/null
	@date > $@

deps: $(DEPS_OK_FILE) ## Install Python dependencies

# ── deps-update ────────────────────────────────────────────────────────────
deps-update: | venv ## Regenerate requirements.{in,txt} via pip-compile
	@printf "Regenerating requirements files...\n"
	@$(PIP) show pip-tools >/dev/null 2>&1 || $(PIP) install -q pip-tools
	@$(VENV_DIR)/bin/pip-compile $(REQUIREMENTS_IN) \
	    -o $(REQUIREMENTS) --strip-extras --quiet
	@rm -f $(DEPS_OK_FILE)
	@printf "requirements.txt updated from $(REQUIREMENTS_IN)\n"

# ── local run ──────────────────────────────────────────────────────────────
check_deno: ## Install deno JS runtime (required by yt-dlp)
	@if command -v deno >/dev/null 2>&1; then \
	  printf "deno found: $$(deno --version | head -n1)\n"; \
	elif [ -x "$$HOME/.deno/bin/deno" ]; then \
	  printf "deno found at $$HOME/.deno/bin/deno (not in PATH)\n"; \
	else \
	  printf "Installing deno...\n"; \
	  curl -fsSL https://deno.land/install.sh | sh; \
	  printf "\nAdd to PATH: export PATH=\"\$$HOME/.deno/bin:\$$PATH\"\n"; \
	fi

check_ffmpeg: ## Install ffmpeg if missing
	@if ! command -v ffmpeg >/dev/null 2>&1; then \
	  printf "ffmpeg not found, attempting to install...\n"; \
	  if command -v apt >/dev/null 2>&1; then \
	    sudo apt update -qq && sudo apt install -y ffmpeg; \
	  elif command -v brew >/dev/null 2>&1; then \
	    brew install ffmpeg; \
	  else \
	    printf "Please install ffmpeg manually: https://ffmpeg.org/download.html\n"; \
	    exit 1; \
	  fi; \
	else \
	  printf "ffmpeg found: $$(ffmpeg -version | head -n1)\n"; \
	fi

run: deps check_ffmpeg check_deno ## Launch the app locally
	@printf "Starting application...\n"
	@PATH="$$HOME/.deno/bin:$$PATH" $(PYTHON_BIN) $(APP)

# ── Docker ─────────────────────────────────────────────────────────────────
docker-build: ## Build the Docker image
	@docker build -t $(IMAGE_NAME) . 2>&1 | tail -3

docker-run: docker-build ## Build (if needed) + run in Docker
	@if [ ! -d "$(HOST_DIR)" ]; then \
	  mkdir -p "$(HOST_DIR)"; \
	fi
	@printf "Launching Docker container — downloads saved to $(HOST_DIR)\n"
	@docker run -it --rm \
	    -v "$(HOST_DIR)":"$(CONTAINER_DIR)" \
	    -e XDG_DOWNLOAD_DIR="$(CONTAINER_DIR)" \
	    "$(IMAGE_NAME)"

# ── cleanup ────────────────────────────────────────────────────────────────
clean: ## Remove venv, logs, and Docker image
	@rm -rf $(VENV_DIR) *.log
	@docker rmi -f $(IMAGE_NAME) 2>/dev/null || true
	@printf "Cleaned: venv, logs, and Docker image\n"

# ── help ───────────────────────────────────────────────────────────────────
help: ## Show this help
	@printf "\nTargets\n"
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?##"}{printf "  %-14s %s\n",$$1,$$2}'
	@printf "\nVariables\n"
	@printf "  HOST_DIR=/path  Host download dir (default: \$$HOME/Downloads, mounted to /app)\n\n"
