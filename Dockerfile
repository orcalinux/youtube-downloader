# ───────────────────────────── Dockerfile ─────────────────────────────
FROM python:3.12-slim

# --- system deps ------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# --- app setup --------------------------------------------------------
WORKDIR /app

# copy dependency files first (leverages Docker layer cache)
COPY requirements.txt requirements.in* ./
RUN pip install --no-cache-dir -r requirements.txt

# copy source
COPY . .

# --- non-root user ----------------------------------------------------
RUN useradd -ms /bin/bash downloader
USER downloader

# default download dir inside container (can be bind-mounted)
ENV XDG_DOWNLOAD_DIR=/downloads

VOLUME ["/downloads"]  # nice UX hint in `docker inspect`

# --- start app --------------------------------------------------------
ENTRYPOINT ["python", "main.py"]
