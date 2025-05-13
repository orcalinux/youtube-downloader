# Makefile
VENV_DIR      := .venv
PYTHON        := python3
PIP           := $(VENV_DIR)/bin/pip
PYTHON_BIN    := $(VENV_DIR)/bin/python
REQUIREMENTS  := requirements.txt
DEPS_OK_FILE  := $(VENV_DIR)/.deps-ok
APP           := main.py
IMAGE_NAME    := youtube-downloader

.PHONY: all run venv deps check_ffmpeg clean \
        docker-build docker-run help

###############################################################################
# Default target
###############################################################################
all: run

###############################################################################
# Virtualenv (created once)
###############################################################################
$(VENV_DIR):
	@echo "Creating virtual environment ..."
	$(PYTHON) -m venv $(VENV_DIR)

venv: $(VENV_DIR)

###############################################################################
# Dependency installation (only when reqs change or first time)
###############################################################################
$(DEPS_OK_FILE): $(REQUIREMENTS) | venv
	@echo "Installing / updating dependencies ..."
	@$(PIP) install --upgrade pip
	@$(PIP) install -r $(REQUIREMENTS)
	@# touch sentinel
	@date > $(DEPS_OK_FILE)

deps: $(DEPS_OK_FILE)

###############################################################################
# FFmpeg check (once per invocation)
###############################################################################
check_ffmpeg:
	@echo "Checking ffmpeg ..."
	@command -v ffmpeg >/dev/null 2>&1 || { \
		echo "ffmpeg not found. Please install ffmpeg."; exit 1; }
	@echo "ffmpeg found."

###############################################################################
# Run the application
###############################################################################
run: deps check_ffmpeg
	@echo "Running app ..."
	@$(PYTHON_BIN) $(APP)

###############################################################################
# Clean helpers
###############################################################################
clean:
	@echo "Removing virtualenv and logs ..."
	@rm -rf $(VENV_DIR) *.log

###############################################################################
# Docker helpers
###############################################################################
docker-build:
	@echo "Building Docker image: $(IMAGE_NAME)"
	docker build -t $(IMAGE_NAME) .

docker-run:
	@echo "Running Docker container from image: $(IMAGE_NAME)"
	docker run -it --rm $(IMAGE_NAME)

###############################################################################
# Help
###############################################################################
help:
	@echo "Targets:"
	@echo "  venv          – create venv (if missing)"
	@echo "  deps          – install/upgrade Python deps (if needed)"
	@echo "  run           – deps + ffmpeg check + run application"
	@echo "  clean         – remove venv and logs"
	@echo "  docker-build  – build Docker image"
	@echo "  docker-run    – run container"
