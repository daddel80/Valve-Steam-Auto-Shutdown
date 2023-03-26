<#
.DESCRIPTION
Steam Auto-Shutdown Script
Author: Thomas Knoefel
Version: 1.0
Created: 2023-03-25

.NOTES
This script checks for Steam downloads and triggers a system shutdown
once all downloads are completed.

Note that in case of a halted download, the script may still detect it
as a download in progress. Be sure to either uninstall or continue the
download process to ensure the script can properly initiate a shutdown.

Dedicated to my son Julian who inspired me to program it!

#>


# Check if the .NET Framework is installed
$framework = Get-ChildItem "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" | Get-ItemPropertyValue -Name Release
if (-not $framework) {
    Write-Error "Das .NET Framework ist nicht installiert."
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# Create a window and a stop button
$window = New-Object System.Windows.Window
$window.Title = 'Steam Auto-Shutdown v1.0    by Thomas Knoefel '
$window.SizeToContent = 'WidthAndHeight'
$window.ResizeMode = 'NoResize'
$window.MinWidth = 400
$window.MinHeight = 200
$window.Background = '#24282f'

$screen = [System.Windows.Forms.Screen]::AllScreens[0]
$window.Left = ($screen.Bounds.Width - $window.MinWidth) / 2
$window.Top = ($screen.Bounds.Height - $window.MinHeight) / 2

$button = New-Object System.Windows.Controls.Button
$button.Content = 'Stop Monitor'
$button.FontSize = 20
$button.Foreground = 'LightGray'
$button.Background = '#383d46'
$button.Margin = New-Object System.Windows.Thickness(0, 10, 0, 10)
$button.Height = 30
$button.Add_Click({$window.Close()})


# Create labels for status display and change font size
$steamLabel = New-Object System.Windows.Controls.Label
$steamLabel.FontSize = 18
$steamLabel.HorizontalAlignment = "Center"
$downloadLabel = New-Object System.Windows.Controls.Label
$downloadLabel.FontSize = 18
$downloadLabel.HorizontalAlignment = "Center"
$shutdownLabel = New-Object System.Windows.Controls.Label
$shutdownLabel.FontSize = 18
$shutdownLabel.HorizontalAlignment = "Center"

# Create a label for displaying the three dots
$dotsLabel = New-Object System.Windows.Controls.Label
$dotsLabel.FontSize = 18
$dotsLabel.Content = "."
$dotsLabel.Foreground = "LightGray"
$dotsLabel.HorizontalAlignment = "Left"
$dotsLabel.Visibility = "Collapsed"

# Set up the layout
$grid = New-Object System.Windows.Controls.Grid
$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
$grid.RowDefinitions[0].Height = New-Object System.Windows.GridLength(40)
$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
$grid.RowDefinitions[1].Height = New-Object System.Windows.GridLength(40)
$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
$grid.RowDefinitions[2].Height = New-Object System.Windows.GridLength(40)
$grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
$grid.RowDefinitions[3].Height = New-Object System.Windows.GridLength(50)

$grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
$grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
$grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))

$grid.ColumnDefinitions[0].Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
$grid.ColumnDefinitions[1].Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Auto)
$grid.ColumnDefinitions[2].Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)


$grid.Children.Add($steamLabel) | Out-Null
$grid.Children.Add($downloadLabel) | Out-Null
$grid.Children.Add($shutdownLabel) | Out-Null
$grid.Children.Add($dotsLabel) | Out-Null
$grid.Children.Add($button) | Out-Null

[System.Windows.Controls.Grid]::SetColumn($steamLabel, 1)
[System.Windows.Controls.Grid]::SetRow($steamLabel, 0)

[System.Windows.Controls.Grid]::SetColumn($downloadLabel, 1)
[System.Windows.Controls.Grid]::SetRow($downloadLabel, 1)

[System.Windows.Controls.Grid]::SetColumn($shutdownLabel, 1)
[System.Windows.Controls.Grid]::SetRow($shutdownLabel, 2)

[System.Windows.Controls.Grid]::SetColumn($dotsLabel, 2)
[System.Windows.Controls.Grid]::SetRow($dotsLabel, 1)

[System.Windows.Controls.Grid]::SetRow($button, 3)
$button.SetValue([System.Windows.Controls.Grid]::ColumnSpanProperty, 3)

$window.Content = $grid

# Write-Log funtion to append a  log file with a tinestamp and a short description
$logFilePath = '.\log.txt'
function Write-Log {
    param (
        [string]$message
    )
    $logMessage = '{0} - {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $message
    Add-Content -Path $logFilePath -Value $logMessage
}


# AnimateDots function for the animated dots
$script:count = 0
function AnimateDots {
    if ($count -eq 0) {
        $dotsLabel.Content = "."
    }
    elseif ($count -eq 1) {
        $dotsLabel.Content = ".."
    }
    elseif ($count -eq 2) {
        $dotsLabel.Content = "..."
    }
    elseif ($count -eq 3) {
        $dotsLabel.Content = "...."
        $script:count = -1
    }
    $script:count++
}

# Get-LibraryFolders function to get the list of Steam library folders
function Get-LibraryFolders {
    param($steamPath)
    $libraryFoldersFile = Join-Path $steamPath 'steamapps\libraryfolders.vdf'
    $content = Get-Content $libraryFoldersFile -ErrorAction SilentlyContinue
    if (-not $content) { return }
    $paths = $content | Select-String -Pattern '"path"\s+"([^"]+)"' | ForEach-Object { $_.Matches.Groups[1].Value }
    $paths
}

# Check-Downloads funtion to Check if any Steam downloads are currently in progress
function Check-Downloads {
    param($folders)
    $downloadRunning = $false
    foreach ($folder in $folders) {
        $downloadingFolder = Join-Path $folder 'steamapps\downloading'
        $files = Get-ChildItem $downloadingFolder -Recurse -ErrorAction SilentlyContinue
        $fileCount = $files.Count
        #Write-Host "Library: $($folder) - Number of files/directories: $($fileCount)"
        if ($files) { $downloadRunning = $true }
    }
    return $downloadRunning
}

# UpdateStatus function to update the labels with status information
$global:timer = New-Object System.Windows.Threading.DispatcherTimer
function UpdateStatus {
    if (-not (Test-Path variable:script:previousDownloadState)) {
        $script:previousDownloadState = $false
    }
    $global:timer.Interval = [TimeSpan]::FromSeconds(3)
	$global:timer.Start()

    $global:timer.Add_Tick({
        
        $downloadRunning = Check-Downloads -folders $libraryFolders
		$dotsLabel.Visibility = "Collapsed"
        if ($downloadRunning) {
            $downloadLabel.Content = 'Downloading game files'
            $downloadLabel.Foreground = 'LightGreen'
            $shutdownLabel.Content = 'Shutdown on download completion'
            $shutdownLabel.Foreground = 'LightGreen'
			$dotsLabel.Visibility = "Visible"
			AnimateDots
            $script:previousDownloadState = $true
        } else {
            $downloadLabel.Content = 'No downloads in progress'
            $downloadLabel.Foreground = 'LightGray'
            $shutdownLabel.Content = 'Shutdown is not enabled'
            $shutdownLabel.Foreground = 'LightGray'
            if ($previousDownloadState) {
                $window.Close()
		Write-Log -message 'Shutdown has been triggered'
                Stop-Computer -Force
            }
        }
    })
}

# Check Steam status
$steam = Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue | Select-Object SteamPath
if ($steam) {
    $steamLabel.Content = 'Steam is installed and ready'
    $steamLabel.Foreground = 'LightGreen'
} else {
    $steamLabel.Content = 'Steam installation path not found'
    $steamLabel.Foreground = 'Red'
}

$libraryFolders = Get-LibraryFolders -steamPath $steam.SteamPath
$window.Add_SourceInitialized({ UpdateStatus })
$window.Add_Closed({ $global:timer.Stop() })
$window.ShowDialog() | Out-Null
