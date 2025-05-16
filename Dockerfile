# ───────────────────────────── Dockerfile ─────────────────────────────
FROM python:3.12-slim

# ── system deps ───────────────────────────────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# ── create non-root user and own /app ─────────────────────────────────
RUN useradd -ms /bin/bash downloader \
    && mkdir -p /app \
    && chown downloader:downloader /app

WORKDIR /app

# ── deps first (good cache) ───────────────────────────────────────────
COPY --chown=downloader:downloader requirements.txt requirements.in* ./
RUN pip install --no-cache-dir -r requirements.txt

# ── copy the source, already owned by downloader ──────────────────────
COPY --chown=downloader:downloader . .

USER downloader

# default download dir (override with HOST_DIR / CONTAINER_DIR from Make)
ENV XDG_DOWNLOAD_DIR=/downloads
VOLUME ["/downloads"]

ENTRYPOINT ["python", "main.py"]
