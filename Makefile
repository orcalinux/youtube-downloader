# Makefile for Professional YouTube Downloader Project

VENV_DIR = .venv
PYTHON = python3
PIP = $(VENV_DIR)/bin/pip
PYTHON_BIN = $(VENV_DIR)/bin/python
REQUIREMENTS = requirements.txt
APP = main.py
IMAGE_NAME = youtube-downloader

.PHONY: all venv install check_ffmpeg run clean help \
        docker-build docker-run

all: run

venv:
	@echo "Creating virtual environment..."
	$(PYTHON) -m venv $(VENV_DIR)

install: venv
	@echo "Installing dependencies..."
	$(PIP) install --upgrade pip
	$(PIP) install -r $(REQUIREMENTS)

check_ffmpeg:
	@echo "Checking ffmpeg..."
	@which ffmpeg > /dev/null || { \
		echo "ffmpeg not found. Please install ffmpeg."; \
		exit 1; \
	}
	@echo "ffmpeg found."

run: install check_ffmpeg
	@echo "Running app..."
	$(PYTHON_BIN) $(APP)

clean:
	@echo "Cleaning up..."
	rm -rf $(VENV_DIR) *.log

docker-build:
	@echo "Building Docker image: $(IMAGE_NAME)"
	docker build -t $(IMAGE_NAME) .

docker-run:
	@echo "Running Docker container from image: $(IMAGE_NAME)"
	docker run -it --rm $(IMAGE_NAME)

help:
	@echo "Available targets:"
	@echo "  venv          - Set up virtual environment"
	@echo "  install       - Install dependencies"
	@echo "  check_ffmpeg  - Verify ffmpeg installation"
	@echo "  run           - Execute downloader"
	@echo "  clean         - Remove virtual environment and logs"
	@echo "  docker-build  - Build Docker image"
	@echo "  docker-run    - Build (if needed) then run Docker container"
	@echo "  help          - Show this help message"
