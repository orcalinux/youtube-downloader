import logging
import os

# Default download directory
DEFAULT_DOWNLOAD_DIR = os.path.expanduser('~/Downloads')

# Quality mapping
VIDEO_QUALITIES = {
    '1': 'bestvideo+bestaudio/best',
    '2': 'bestvideo[height<=1080]+bestaudio/best[height<=1080]',
    '3': 'bestvideo[height<=720]+bestaudio/best[height<=720]',
    '4': 'bestvideo[height<=480]+bestaudio/best[height<=480]'
}

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("downloader.log"),
        logging.StreamHandler()
    ]
)
