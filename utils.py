import logging
from rich.prompt import Prompt
from rich.console import Console
import validators
from urllib.parse import urlparse
import os
import sys

console = Console()

def safe_prompt(prompt_str, **kwargs):
    try:
        return Prompt.ask(prompt_str, **kwargs)
    except KeyboardInterrupt:
        # Print a blank line so the '^C' remains on the same line as the prompt
        print("")
        console.print("[bold red]❌ Operation cancelled by user.[/bold red]")
        logging.warning("Download interrupted by user (SIGINT).")
        sys.exit(0)

def prompt_choice(prompt, choices, default):
    return safe_prompt(
        prompt,
        choices=choices,
        default=default,
        show_choices=True,
        show_default=True
    )

def prompt_directory():
    default_dir = os.path.expanduser('~/Downloads')
    return safe_prompt(
        "Download directory",
        default=default_dir,
        show_default=True
    )

def validate_url(url):
    if not validators.url(url):
        return False
    domain = urlparse(url).netloc
    valid_domains = ['youtube.com', 'www.youtube.com', 'youtu.be']
    return domain in valid_domains

def prompt_url(prompt_str):
    while True:
        url = safe_prompt(prompt_str)
        if validate_url(url):
            return url
        console.print("[bold red]⚠ Invalid YouTube URL. Please try again.[/bold red]")

def prompt_yes_no(prompt_str, default='y'):
    choice = safe_prompt(
        f"{prompt_str} (y/n)",
        choices=['y', 'n'],
        default=default,
        show_default=True
    )
    return choice.lower() == 'y'

def prompt_video_selection(videos):
    console.print("\n[bold magenta]Playlist videos:[/bold magenta]")
    for i, video in enumerate(videos, 1):
        console.print(f"{i}. {video.get('title', 'No Title')}")
    indices = safe_prompt(
        "Select videos (e.g., 1,3,5) [all]",
        default='',
        show_default=False
    )
    if not indices:
        return videos
    selected_indices = [int(i.strip())-1 for i in indices.split(',') if i.strip().isdigit()]
    return [videos[i] for i in selected_indices if 0 <= i < len(videos)]
