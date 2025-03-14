import downloader
import utils
import config
import logging
from rich.console import Console
from rich.panel import Panel
from rich import box

console = Console()

def main():
    console.print(Panel("🎬 [bold cyan]YouTube Downloader[/bold cyan] 🎬", box=box.DOUBLE))

    console.print("\n[bold cyan]Download Mode:[/bold cyan]")
    console.print("[bold green]1[/bold green]: Single Video")
    console.print("[bold green]2[/bold green]: Playlist\n")

    # Safely prompt for download mode
    choice = utils.prompt_choice(
        "[bold yellow]Select download mode[/bold yellow]",
        choices=['1', '2'],
        default='1'
    )

    download_dir = utils.prompt_directory()
    console.print(f"[bold yellow]Download directory:[/bold yellow] {download_dir}\n")

    # Safely prompt for URL
    url = utils.prompt_url("[bold green]Enter YouTube URL[/bold green]")

    console.print("\n[bold cyan]Available Quality Options:[/bold cyan]")
    console.print("[bold green]1[/bold green]: Best quality available")
    console.print("[bold green]2[/bold green]: High quality (1080p or lower)")
    console.print("[bold green]3[/bold green]: Medium quality (720p or lower)")
    console.print("[bold green]4[/bold green]: Low quality (480p or lower)\n")

    quality = utils.prompt_choice(
        "[bold yellow]Choose video quality[/bold yellow]",
        choices=['1', '2', '3', '4'],
        default='1'
    )
    selected_format = config.VIDEO_QUALITIES[quality]

    try:
        # Regular logic for single video or playlist
        if choice == '1':
            console.print("[bold cyan]🚀 Downloading single video...[/bold cyan]")
            downloader.download_video(url, selected_format, download_dir)
        else:
            videos = downloader.fetch_playlist_videos(url)
            if utils.prompt_yes_no("Download entire playlist?"):
                console.print("[bold cyan]🚀 Downloading entire playlist...[/bold cyan]")
                downloader.download_videos(videos, selected_format, download_dir)
            else:
                selected = utils.prompt_video_selection(videos)
                console.print("[bold cyan]🚀 Downloading selected videos...[/bold cyan]")
                downloader.download_videos(selected, selected_format, download_dir)

        console.print("\n[bold green]✅ Download completed successfully![/bold green]")

    except Exception as e:
        console.print(f"\n[bold red]❌ Error:[/bold red] {e}")
        logging.exception(f"Unexpected error: {e}")
    finally:
        logging.info("Downloader session ended.")
        console.print("\n[bold blue]👋 Goodbye![/bold blue]")


if __name__ == "__main__":
    main()
