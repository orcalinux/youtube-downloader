# Makefile for Professional YouTube Downloader Project

VENV_DIR = .venv
PYTHON = python3
PIP = $(VENV_DIR)/bin/pip
PYTHON_BIN = $(VENV_DIR)/bin/python
REQUIREMENTS = requirements.txt
APP = main.py

.PHONY: all venv install check_ffmpeg run clean help

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

help:
	@echo "Available targets:"
	@echo "  venv         - Set up virtual environment"
	@echo "  install      - Install dependencies"
	@echo "  check_ffmpeg - Verify ffmpeg installation"
	@echo "  run          - Execute downloader"
	@echo "  clean        - Remove virtual environment and logs"
	@echo "  help         - Show this help message"
