# KHInsider Multi-Downloader

A professional, high-quality music downloader script for khinsider.com. It is designed to be lightweight, stable, and user-friendly with a CLI GUI.

## Features

- **FLAC & MP3 Support**: Download high-quality FLAC files with an automatic fallback to MP3 if FLAC is unavailable.
- **Smart Resume**: Automatically detects existing files and verifies integrity using file size comparison.
- **Auto-Subfolder**: Automatically parses the album name and creates a dedicated folder for each album.
- **Intelligent Pathing**: Automatically detects moved Windows "Downloads" folders (D:\Downloads, etc.) via Registry.
- **Robust Connection**: Support for custom delays (IP protection) and retry logic (including infinite retries).
- **Temporary File Handling**: Uses `.tmp` extensions during download to prevent partial/corrupted files.
- **Multi-Language**: Toggle between English and Traditional Chinese seamlessly.

## Requirements

- **OS**: Windows 10 or 11
- **PowerShell**: 5.1 or 7.x (Built-in)
- **Permissions**: Ensure your execution policy allows running scripts, or run the `.bat` wrapper.

## How to Use

1. Copy the code into a file named `KH_Downloader.bat`.
2. Run the file by double-clicking it.
3. Paste the KHInsider album URL (e.g., `https://downloads.khinsider.com/game-soundtracks/album/xxx`).
4. Press `S` to start downloading.