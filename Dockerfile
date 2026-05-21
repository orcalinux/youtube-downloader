FROM python:3.12-slim

RUN apt-get update \
    &&     apt-get install -y --no-install-recommends ffmpeg ca-certificates curl unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deno.land/install.sh | sh \
    && ln -s /root/.deno/bin/deno /usr/local/bin/deno

ENV PATH="/root/.deno/bin:${PATH}"

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Pre-cache yt-dlp remote challenge solver so first-run is instant
RUN python3 << 'EOF' 2>/dev/null || true
from yt_dlp import YoutubeDL
YoutubeDL({'remote_components': {'ejs:github'}, 'quiet': True}).extract_info(
    'https://youtu.be/dQw4w9WgXcQ', download=False)
EOF

COPY . .

ENV XDG_DOWNLOAD_DIR=/root/Downloads

ENTRYPOINT ["python", "main.py"]
