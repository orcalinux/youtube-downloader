from yt_dlp import YoutubeDL
import os
import logging
from tqdm import tqdm

def download_video(url, selected_format, download_dir):
    os.makedirs(download_dir, exist_ok=True)
    ydl_opts = {
        'format': selected_format,
        'outtmpl': os.path.join(download_dir, '%(title)s.%(ext)s'),
        'quiet': True,
        'progress_hooks': [progress_hook],
    }
    try:
        with YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])
    except Exception as e:
        logging.exception(f"Failed to download video: {e}")
        raise

def fetch_playlist_videos(url):
    ydl_opts = {
        'quiet': True,
        'extract_flat': True
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
        download_video(video['url'], selected_format, download_dir)

def progress_hook(d):
    if d['status'] == 'finished':
        logging.info(f"Downloaded: {d['filename']}")
