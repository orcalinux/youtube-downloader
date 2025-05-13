###############################################################################
# YouTube-Downloader – Makefile
#
# QUICK COMMANDS
#   make run                       -> local venv run (auto-installs deps)
#   make docker-run [HOST_DIR=/x]  -> build if needed + launch container
#   make deps-update               -> regenerate requirements.{in,txt}
#   make help                      -> list all targets / variables
###############################################################################

# ─────────────────────────── Core configuration ──────────────────────────────
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

HOST_DIR        ?= $(HOME)/Downloads
CONTAINER_DIR   := /downloads

BUILD_DEPS      := Dockerfile $(REQUIREMENTS) $(wildcard *.py utils/*.py)

# ─────────────────────── Colour helpers for help banner ──────────────────────
B := \033[1m
G := \033[32m
NC := \033[0m

# ───────────────────────────── PHONY targets ────────────────────────────────
.PHONY: all help \
        run venv deps deps-update check_ffmpeg clean \
        docker-build docker-run

###############################################################################
# Default: local run
###############################################################################
all: run                                    ## Local venv run (default target)

###############################################################################
# Virtual-env & idempotent dependency install
###############################################################################
$(VENV_DIR):
	@echo "Creating virtual environment …"
	$(PYTHON) -m venv $@

venv: $(VENV_DIR)                           ## Create venv (dev)

$(DEPS_OK_FILE): $(REQUIREMENTS) | venv
	@echo "Installing / upgrading dependencies …"
	@$(PIP) install --upgrade pip
	@$(PIP) install -r $(REQUIREMENTS)
	@date > $@

deps: $(DEPS_OK_FILE)                       ## Install / upgrade deps (dev)

###############################################################################
# deps-update – rebuild requirements.{in,txt}
###############################################################################
deps-update: | venv                         ## Refresh dependency files
	@echo "Regenerating requirements.{in,txt} …"

	@# Ensure helper tools exist inside the venv
	@$(PIP) show pipreqs  >/dev/null 2>&1 || $(PIP) install --quiet pipreqs
	@$(PIP) show pip-tools >/dev/null 2>&1 || $(PIP) install --quiet pip-tools

	@IGNORES=".git,.venv,__pycache__,build,dist,images,docs" ;\
	echo "  • running pipreqs quietly (ignoring $$IGNORES)" ;\
	$(VENV_DIR)/bin/pipreqs . --force \
	    --encoding=utf-8 \
	    --ignore $$IGNORES \
	    --savepath $(REQUIREMENTS_IN) \
	    >/dev/null 2>&1

	@echo "  • pinning versions with pip-compile (quiet)"
	@$(VENV_DIR)/bin/pip-compile $(REQUIREMENTS_IN) -o $(REQUIREMENTS) \
	    --strip-extras --quiet

	@rm -f $(DEPS_OK_FILE)                    # reinstall on next make deps
	@echo "Dependency files updated."

###############################################################################
# Local ffmpeg sanity check
###############################################################################
check_ffmpeg:
	@command -v ffmpeg >/dev/null || { \
	  echo "ffmpeg not found — please install"; exit 1; }
	@echo "ffmpeg found."

###############################################################################
# Local run
###############################################################################
run: deps check_ffmpeg                      ## Local venv run
	@echo "Running app locally …"
	@$(PYTHON_BIN) $(APP)

###############################################################################
# Docker – rebuild only when sources change
###############################################################################
$(DOCKER_STAMP): $(BUILD_DEPS)
	@echo "🔨  Building Docker image '$(IMAGE_NAME)' …"
	docker build -t $(IMAGE_NAME) .
	@date > $@

docker-build: $(DOCKER_STAMP)               ## Force Docker rebuild

###############################################################################
# Docker – run
###############################################################################
docker-run: docker-build                    ## Launch interactive container
	@echo "🚀  Launching container (host dir → $(HOST_DIR)) …"
	docker run -it --rm \
		-v $(HOST_DIR):$(CONTAINER_DIR) \
		-e XDG_DOWNLOAD_DIR=$(CONTAINER_DIR) \
		--name $(IMAGE_NAME) \
		$(IMAGE_NAME)

###############################################################################
# Cleanup
###############################################################################
clean:                                      ## Remove venv, logs, docker stamp
	@echo "Cleaning workspace …"
	@rm -rf $(VENV_DIR) *.log $(DOCKER_STAMP)

###############################################################################
# Help
###############################################################################
help:
	@echo
	@echo "$(B)Targets$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?##"}{printf "  $(G)%-15s$(NC) %s\n",$$1,$$2}'
	@echo
	@echo "$(B)Overridable variables$(NC)"
	@echo "  HOST_DIR=/path    Bind-mount for docker-run (default: $$HOME/Downloads)"
	@echo
