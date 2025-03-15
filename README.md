# YouTube Downloader

This project provides a simple and user-friendly command-line tool to download single YouTube videos or entire playlists. The interface uses [Rich](https://github.com/Textualize/rich) for beautiful, interactive prompts, and gracefully handles **Ctrl+C** (interrupt signals) without flooding the console with Python tracebacks.

## New Feature: Docker Support

In addition to running the downloader locally with Python, you can now run it inside a **Docker container**, making it even easier for others to use without installing Python or other dependencies.

1. **Build the Docker image** (from the project root):

   ```bash
   docker build -t youtube-downloader .
   ```

2. **Run the container**:

   ```bash
   docker run -it --rm youtube-downloader
   ```

   - `-it` (interactive + TTY) allows you to see the interactive prompts and respond in real time.
   - `--rm` automatically removes the container when it stops, so you don’t clutter your system with stopped containers.

3. **Share the Docker image**:
   - (Optional) If you want others to use your pre-built image, push it to a registry (e.g., Docker Hub):
     ```bash
     docker tag youtube-downloader <your-dockerhub-username>/youtube-downloader:latest
     docker push <your-dockerhub-username>/youtube-downloader:latest
     ```
   - Then others can simply:
     ```bash
     docker pull <your-dockerhub-username>/youtube-downloader:latest
     docker run -it --rm <your-dockerhub-username>/youtube-downloader:latest
     ```

That’s it! Now anyone with Docker installed can use the YouTube Downloader without manually installing Python or the required libraries.

---

## Features

1. **Single Video or Playlist**:

   - Prompt-based selection: choose to download a single video or an entire YouTube playlist.

2. **User-Friendly Prompts**:

   - Uses [Rich Prompt](https://rich.readthedocs.io/en/stable/prompt.html) for colorful and interactive user input.
   - Detailed explanations for each prompt (download mode, video quality, etc.).

3. **Graceful Interruption**:

   - Pressing **Ctrl+C** at any prompt immediately cancels the operation without displaying an exception traceback.
   - Displays a short `Operation cancelled by user.` message and logs the interruption event (including a timestamp) in both the console and a log file.

4. **Logging**:

   - Uses Python’s logging module to capture all warnings, errors, and interruptions.
   - Saves logs to `downloader.log` (or your chosen filename) for easy debugging and auditing.

5. **Quality Selection**:

   - Pick from “Best,” “High (1080p),” “Medium (720p),” or “Low (480p)” quality profiles.

6. **History Support** (optional):
   - Retains a history of previously entered directories/URLs for easy recall (if configured with `readline`).

---

## Getting Started (Local Installation)

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/yourusername/youtube-downloader.git
   cd youtube-downloader
   ```

2. **Install Dependencies** (via `make`):

   ```bash
   make install
   ```

   This sets up a local virtual environment (`.venv`) and installs all required packages from `requirements.txt`.

3. **Check ffmpeg**:

   ```bash
   make check_ffmpeg
   ```

   Ensures `ffmpeg` is installed on your system.

4. **Run the Application**:
   ```bash
   make run
   ```
   or
   ```bash
   .venv/bin/python main.py
   ```

---

## Usage

1. **Select Mode**:

   - Press **`1`** for a single video.
   - Press **`2`** to download a playlist.

2. **Enter Download Directory**:

   - Defaults to `~/Downloads`.
   - Press Enter to accept default, or specify a custom path.

3. **Enter YouTube URL**:

   - Checks validity (supports `youtube.com` and `youtu.be`).
   - Prints an error message if invalid.

4. **Choose Video Quality**:

   - **1**: Best (highest available)
   - **2**: High (up to 1080p)
   - **3**: Medium (up to 720p)
   - **4**: Low (up to 480p)

5. **Download**:

   - For single video mode, starts downloading immediately.
   - For playlist mode, either downloads all videos or lets you choose specific ones from a list.

6. **Cancel at Any Time**:
   - Press **Ctrl+C** at any prompt if you change your mind.
   - The program prints `^C` on the same line, followed by:
     ```
     ❌ Operation cancelled by user.
     2025-03-14 19:19:10,455 - WARNING - Download interrupted by user (SIGINT).
     ```
     Then it gracefully exits without showing a traceback.

---

## Logging

- All log messages, including interruptions, are appended to **`downloader.log`** by default.
- When **Ctrl+C** is pressed:
  - A warning is logged with a timestamp and the message **"Download interrupted by user (SIGINT)."**

---

## Troubleshooting

- **Ctrl+C Not Working**:

  - Make sure you’re using the included `safe_prompt` wrapper in `utils.py`.
  - Confirm your logging setup has a **StreamHandler** if you want to see log messages in the console.

- **`ffmpeg not found`**:

  - Install `ffmpeg` for your operating system. For example, on Ubuntu/Debian:
    ```bash
    sudo apt-get update
    sudo apt-get install ffmpeg
    ```

- **Permission Issues**:
  - Ensure you have write permissions to your chosen download directory.

---

## Contributing

1. **Fork** the repository.
2. **Create** a new branch for your feature.
3. **Commit** your changes.
4. **Push** to your fork.
5. **Submit** a Pull Request (PR).

---

## License

This project is licensed under the [MIT License](LICENSE).
Feel free to copy, modify, and distribute under the same license.
