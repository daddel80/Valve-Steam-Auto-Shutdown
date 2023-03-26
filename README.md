# Steam Auto-Shutdown

Steam Auto-Shutdown is a utility that monitors Steam downloads and triggers a system shutdown when all downloads are completed. This tool is especially useful for users who want to leave their computer unattended while downloading large game files.

## Features

- Monitor Steam downloads in real-time
- Automatically shut down the computer when all downloads are completed
- User-friendly GUI to display the status of downloads and shutdown
- Log file to record the shutdown events

## Requirements

- Windows operating system
- .NET Framework installed
- Steam installed

## Installation

1. Download the `SteamAutoShutdown.ps1` script from this repository.
2. Save the script in a folder on your computer.

## Usage

1. Open PowerShell.
2. Navigate to the folder where you saved the `SteamAutoShutdown.ps1` script.
3. Run the script:
    ```
    .\SteamAutoShutdown.ps1
    ```

## Note

Halted downloads are also detected as downloads in progress. If a download is detected but there is no visible download in progress, please check for stopped downloads and clean them up by uninstalling or finishing the download.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)
