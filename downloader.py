from yt_dlp import YoutubeDL
import os
import logging
from tqdm import tqdm
from rich.progress import (
    Progress,
    BarColumn,
    DownloadColumn,
    TransferSpeedColumn,
    TimeRemainingColumn,
    TextColumn,
)
from rich.console import Console

console = Console()

def download_video(url, selected_format, download_dir):
    os.makedirs(download_dir, exist_ok=True)

    progress = Progress(
        TextColumn("[bold blue]{task.fields[name]}", justify="left"),
        BarColumn(),
        DownloadColumn(),
        TransferSpeedColumn(),
        TimeRemainingColumn(),
        console=console,
    )

    task_id = None
    _prev_filename = None

    def hook(d):
        nonlocal task_id, _prev_filename
        if d['status'] == 'downloading':
            total = d.get('total_bytes') or d.get('total_bytes_estimate') or 0
            filename = d.get('filename', '')

            if filename != _prev_filename and _prev_filename is not None:
                if task_id is not None:
                    progress.remove_task(task_id)
                task_id = None
            _prev_filename = filename

            if task_id is None:
                task_id = progress.add_task(
                    "Downloading", total=total,
                    name=os.path.basename(filename) or 'video',
                )
            progress.update(task_id, completed=d.get('downloaded_bytes', 0))
        elif d['status'] == 'finished' and task_id is not None:
            completed = d.get('total_bytes', 0) or 1
            progress.update(task_id, completed=completed)

    ydl_opts = {
        'format': selected_format,
        'outtmpl': os.path.join(download_dir, '%(title)s.%(ext)s'),
        'quiet': True,
        'noprogress': True,
        'progress_hooks': [hook],
        'remote_components': {'ejs:github'},
    }
    try:
        with progress:
            with YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])
    except Exception as e:
        logging.exception(f"Failed to download video: {e}")
        raise

def fetch_playlist_videos(url):
    ydl_opts = {
        'quiet': True,
        'extract_flat': True,
        'remote_components': {'ejs:github'},
    }
    try:
        with YoutubeDL(ydl_opts) as ydl:
            info_dict = ydl.extract_info(url, download=False)
        return info_dict.get('entries', [])
    except Exception as e:
        logging.exception(f"Failed to fetch playlist: {e}")
        raise

def download_videos(videos, selected_format, download_dir):
    for video in tqdm(videos, desc="Downloading"):
        video_url = video.get('url') or f"https://www.youtube.com/watch?v={video['id']}"
        download_video(video_url, selected_format, download_dir)
