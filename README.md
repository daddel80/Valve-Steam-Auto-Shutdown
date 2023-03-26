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

1. Clone or download this repository to your local machine.
2. Locate the `SteamAutoShutdown_Binary.zip` file in the repository folder.
3. Extract the contents of the `SteamAutoShutdown_Binary.zip` file. The password is "steam".
4. Run the `SteamAutoShutdown.exe` file from the extracted folder to start the application.

## Usage

1. Start the Steam Auto-Shutdown utility by running the `SteamAutoShutdown.exe` file.
2. The application will display the status of Steam installation and downloads.
3. Once all downloads are completed, the utility will automatically initiate a system shutdown.
4. To stop monitoring downloads and close the application, click the "Stop Monitor" button.

## Note

Halted downloads are also detected as downloads in progress. If a download is detected but there is no visible download in progress, please check for stopped downloads and clean them up by uninstalling or finishing the download.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)
