# utils.py
import os
import sys
from urllib.parse import urlparse

from rich.console import Console
from rich.prompt import Prompt
import validators

console = Console()

# ──────────────────────────── Tab-completion support ─────────────────────────
try:
    from prompt_toolkit import PromptSession
    from prompt_toolkit.completion import PathCompleter
    from prompt_toolkit.shortcuts import CompleteStyle
    from prompt_toolkit.formatted_text import ANSI 
    _HAS_PT = True
except ImportError:
    _HAS_PT = False


# ───────────────────────────── Helper functions ──────────────────────────────
def safe_prompt(prompt_str, **kwargs):
    """Wrap Prompt.ask so Ctrl-C offers quit/resume instead of crashing."""
    while True:
        try:
            return Prompt.ask(prompt_str, **kwargs)
        except KeyboardInterrupt:
            print("")  # keep ^C on the same line
            console.print("[bold red]⛔ Interrupted![/bold red]")
            choice = Prompt.ask(
                "Do you really want to exit?",
                choices=["y", "n"],
                default="y",
                show_choices=True,
                show_default=True,
            )
            if choice.lower() == "y":
                console.print("[bold blue]Goodbye![/bold blue]")
                sys.exit(0)
            console.print("[bold green]Resuming...[/bold green]")


def prompt_choice(prompt, choices, default):
    return safe_prompt(
        prompt,
        choices=choices,
        default=default,
        show_choices=True,
        show_default=True,
    )


# ─────────────────────── DIRECTORY PROMPT WITH COMPLETION ────────────────────
def prompt_directory():
    """
    Bash-style TAB completion + Rich-coloured prompt.
    """
    default_dir = os.path.expanduser("~/Downloads")

    YELLOW = "\033[1;33m"
    CYAN   = "\033[1;36m" 
    RESET  = "\033[0m"

    from prompt_toolkit.formatted_text import ANSI

    ansi_prompt = ANSI(
        f"{YELLOW}Download directory{RESET} "
        f"[{CYAN}{default_dir}{RESET}]: "
    )

    while True:
        try:
            if _HAS_PT:
                session = PromptSession(
                    completer=PathCompleter(expanduser=True,
                                            only_directories=True),
                    complete_while_typing=False,
                    complete_style=CompleteStyle.READLINE_LIKE,
                )
                text = session.prompt(ansi_prompt).strip() or default_dir
            else:
                text = Prompt.ask(
                    "Download directory",
                    default=default_dir,
                    show_default=True,
                ).strip()

            return os.path.abspath(os.path.expanduser(text))

        except KeyboardInterrupt:
            print("")
            console.print("[bold red]⛔ Interrupted![/bold red]")
            if Prompt.ask("Do you really want to exit?", choices=["y", "n"],
                          default="y") == "y":
                console.print("[bold blue]Goodbye![/bold blue]")
                sys.exit(0)
            console.print("[bold green]Resuming...[/bold green]")

# ──────────────────────────── URL helpers ────────────────────────────────────
def validate_url(url):
    if not validators.url(url):
        return False
    domain = urlparse(url).netloc
    valid_domains = ["youtube.com", "www.youtube.com", "youtu.be"]
    return domain in valid_domains


def prompt_url(prompt_str):
    while True:
        url = safe_prompt(prompt_str)
        if validate_url(url):
            return url
        console.print(
            "[bold red]⚠ Invalid YouTube URL. Please try again.[/bold red]"
        )


def prompt_yes_no(prompt_str, default="y"):
    choice = safe_prompt(
        f"{prompt_str} (y/n)",
        choices=["y", "n"],
        default=default,
        show_default=True,
    )
    return choice.lower() == "y"


def prompt_video_selection(videos):
    console.print("\n[bold magenta]Playlist videos:[/bold magenta]")
    for i, video in enumerate(videos, 1):
        console.print(f"{i}. {video.get('title', 'No Title')}")
    indices = safe_prompt(
        "Select videos (e.g., 1,3,5) [all]",
        default="",
        show_default=False,
    )
    if not indices:
        return videos
    selected_indices = [
        int(i.strip()) - 1 for i in indices.split(",") if i.strip().isdigit()
    ]
    return [
        videos[i] for i in selected_indices if 0 <= i < len(videos)
    ]
