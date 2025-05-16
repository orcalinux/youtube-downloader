###############################################################################
# YouTube-Downloader – Makefile  (quiet, colour status, no emojis)
###############################################################################
# make run                → local venv run  (silent dependency install)
# make docker-run         → build if needed + launch container
# make deps-update        → regenerate requirements.{in,txt}
# make help               → list all targets / variables
###############################################################################

# ── core paths ───────────────────────────────────────────────────────────────
VENV_DIR        := .venv
PYTHON          := python3
PIP             := $(VENV_DIR)/bin/pip
PYTHON_BIN      := $(VENV_DIR)/bin/python

REQUIREMENTS    := requirements.txt
REQUIREMENTS_IN := requirements.in
DEPS_OK_FILE    := $(VENV_DIR)/.deps-ok
APP             := main.py

IMAGE_NAME      := youtube-downloader
DOCKER_STAMP    := .docker-built

HOST_DIR        ?= $(HOME)/Downloads   # bind mount on host
CONTAINER_DIR   := /downloads          # bind mount inside container

BUILD_DEPS      := Dockerfile $(REQUIREMENTS) $(wildcard *.py utils/*.py)

# ── ANSI colours ─────────────────────────────────────────────────────────────
CLR_RESET  := \033[0m
CLR_YELLOW := \033[1;33m
CLR_CYAN   := \033[1;36m
CLR_GREEN  := \033[1;32m
CLR_MAG    := \033[1;35m
CLR_RED    := \033[1;31m

# ── phony targets ────────────────────────────────────────────────────────────
.PHONY: all help run venv deps deps-update check_ffmpeg clean docker-build docker-run

###############################################################################
all: run ## Default target – alias for `make run`
###############################################################################

# ── virtual-env & deps ───────────────────────────────────────────────────────
$(VENV_DIR): ## Create a local Python virtual-environment
	@printf "$(CLR_YELLOW)Creating virtual environment...$(CLR_RESET)\n"
	@$(PYTHON) -m venv $@ >/dev/null

venv: $(VENV_DIR) ## Explicitly create the venv (idempotent)

$(DEPS_OK_FILE): $(REQUIREMENTS) | venv ## Install/upgrade Python deps
	@printf "$(CLR_YELLOW)Installing Python packages...$(CLR_RESET)\n"
	@$(PIP) install --quiet --upgrade pip >/dev/null
	@$(PIP) install --quiet -r $(REQUIREMENTS) >/dev/null
	@date > $@

deps: $(DEPS_OK_FILE) ## Ensure deps are installed (auto-called by run)

# ── deps-update ──────────────────────────────────────────────────────────────
deps-update: | venv ## Re-generate requirements.{in,txt} from imports
	@printf "$(CLR_CYAN)Regenerating requirements files...$(CLR_RESET)\n"
	@$(PIP) show pipreqs  >/dev/null 2>&1 || $(PIP) install -q pipreqs
	@$(PIP) show pip-tools >/dev/null 2>&1 || $(PIP) install -q pip-tools
	@IGNORES=".git,.venv,__pycache__,build,dist,images,docs" ; \
	$(VENV_DIR)/bin/pipreqs . --force --encoding=utf-8 \
	    --ignore $$IGNORES --savepath $(REQUIREMENTS_IN) >/dev/null 2>&1
	@$(VENV_DIR)/bin/pip-compile $(REQUIREMENTS_IN) \
	    -o $(REQUIREMENTS) --strip-extras --quiet
	@rm -f $(DEPS_OK_FILE)
	@printf "$(CLR_GREEN)requirements.txt updated$(CLR_RESET)\n"

# ── local run ────────────────────────────────────────────────────────────────
check_ffmpeg: ## Abort if ffmpeg is missing on the host
	@command -v ffmpeg >/dev/null || { \
	  printf "$(CLR_RED)ffmpeg not found—install it$(CLR_RESET)\n"; exit 1; }

run: deps check_ffmpeg ## Launch the app locally inside the venv
	@printf "$(CLR_GREEN)Starting application [local]...$(CLR_RESET)\n"
	@$(PYTHON_BIN) $(APP)

# ── Docker build & run ───────────────────────────────────────────────────────
$(DOCKER_STAMP): $(BUILD_DEPS) ## Build docker image if sources changed
	@printf "$(CLR_YELLOW)Building Docker image...$(CLR_RESET)\n"
	@docker build --progress=plain -t $(IMAGE_NAME) . >/dev/null
	@date > $@

docker-build: $(DOCKER_STAMP) ## Force build the image now

docker-run: docker-build ## Build (if needed) + run the container
	@printf "$(CLR_GREEN)Launching container → $(HOST_DIR)$(CLR_RESET)\n"
	@docker run -it --rm \
	    -v $(HOST_DIR):$(CONTAINER_DIR) \
	    -e XDG_DOWNLOAD_DIR=$(CONTAINER_DIR) \
	    --name $(IMAGE_NAME) \
	    $(IMAGE_NAME)

# ── cleanup ──────────────────────────────────────────────────────────────────
clean: ## Wipe venv, logs and docker-build stamp
	@printf "$(CLR_MAG)Cleaning workspace...$(CLR_RESET)\n"
	@rm -rf $(VENV_DIR) *.log $(DOCKER_STAMP)

# ── help ─────────────────────────────────────────────────────────────────────
help: ## Show this help
	@printf "\n$(CLR_GREEN)Targets$(CLR_RESET)\n"
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?##"}{printf "  %-14s %s\n",$$1,$$2}'
	@printf "\n$(CLR_GREEN)Variable overrides$(CLR_RESET)\n"
	@printf "  HOST_DIR=/path        Host download directory (default: $$HOME/Downloads)\n"
	@printf "  CONTAINER_DIR=/path   Mount point *inside* container (default: /downloads)\n\n"
