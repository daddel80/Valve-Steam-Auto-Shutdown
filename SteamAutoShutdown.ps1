<#
.DESCRIPTION
Steam Auto-Shutdown Script
Author: Thomas Knoefel
Version: 1.1
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
    Write-Error "The .NET Framework is not installed."
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# Create a window and a stop button
$window = New-Object System.Windows.Window
$window.Title = 'Steam Auto-Shutdown v1.1    by Thomas Knoefel '
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
    $steamLabel.Content = 'Steam detected and ready'
    $steamLabel.Foreground = 'LightGreen'
} else {
    $steamLabel.Content = 'Steam installation path not found'
    $steamLabel.Foreground = 'Red'
}

$libraryFolders = Get-LibraryFolders -steamPath $steam.SteamPath
$window.Add_SourceInitialized({ UpdateStatus })
$window.Add_Closed({ $global:timer.Stop() })
$window.ShowDialog() | Out-Null

# SIG # Begin signature block
# MIIFsQYJKoZIhvcNAQcCoIIFojCCBZ4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/2oR5xpdIgbecOlDpdyV86wF
# SISgggNCMIIDPjCCAiagAwIBAgIQFJ3Z2Ni5y59ALHOvroNb1TANBgkqhkiG9w0B
# AQsFADAkMSIwIAYDVQQDDBlUaG9tYXMgS25vZWZlbCBbZGFkZGVsODBdMB4XDTIz
# MDQwOTEyMzU0OVoXDTI0MDQwOTEyNTU0OVowJDEiMCAGA1UEAwwZVGhvbWFzIEtu
# b2VmZWwgW2RhZGRlbDgwXTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AKoRDE8GWRvu8tEltZnBoBBHabT9jiABylQm9W1eOhEAkFi3ym9tdVp1hMqzQMzj
# rA/f9NITbrrIXR5K1QDyPEY1mijuNMl59IjSJVRc9MDTY7HfesDCDvSfqQpMjb4F
# 2oJalVuWgTXs/6ZhPVHMcLR+z0QCw3g3rz7AEtbjYWw6GLPXQg3zjt5JBKkP2yVg
# mnRvx7X0iwx616FXucwGkvI84GFn3rC3pF92ljDs0gei+73s4MRpkBYbBSTNICY6
# 0WFavcLxhltjfzlkQpK0ncMhfHeWBb8SuufqHeSOabIwVbowIVX7Kq7nbQUiK/57
# LNtYxDLv8/vH05WEtMx06OUCAwEAAaNsMGowDgYDVR0PAQH/BAQDAgeAMCQGA1Ud
# EQQdMBuCGVRob21hcyBLbm9lZmVsIFtkYWRkZWw4MF0wEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwHQYDVR0OBBYEFD/n3FYP9YUkLmU43kmmT1zn7+j9MA0GCSqGSIb3DQEB
# CwUAA4IBAQB0yp2UJkEBzeFUTS03xYs+eDQ/DXGOkCZZxFHgpodx7iaGq2nuQ1O+
# SS5WQI80sxuVBgdkZqyusSaZo9HWCXJkBFWAXQcvKfNZF3M8p70bV6r4QDodqOJR
# VO8GTft3TmT8pFTlWZVm3wR0dQp9C7rIaOyEudREmv6IHIDL/WaODzwWhkYk3y7B
# nCaX8H0rtrJCb2naODTt5GAp35Wu+8tnXu/XJ0OjEmNtdjU6WuJL9VAKODjkObi7
# eCdYAzXLFd1WQchH47oVZPaYUpLCosEl+kiSstIeCmEMZDLZo5tgMheGyjMI6lqq
# o9tNzy5zvf4yAdOgdtscxRavJ1eYYIrqMYIB2TCCAdUCAQEwODAkMSIwIAYDVQQD
# DBlUaG9tYXMgS25vZWZlbCBbZGFkZGVsODBdAhAUndnY2LnLn0Asc6+ug1vVMAkG
# BSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJ
# AzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMG
# CSqGSIb3DQEJBDEWBBQPMDsWPLJ3XS0oCey6LAagGnuSbzANBgkqhkiG9w0BAQEF
# AASCAQAMFjKqdSG+IAjh/UUoJrFeX9N6Ic/v+RIdewDvL5wMdEAMrydT2hQch0vd
# ZyVKGw9225VhAei+d19eQD3Oj/FAe3LyBh+zesSPkEH6DrES99w8yFgAYR0SsWt2
# 66yOQyJfxvvsDkLbzv8yig7knfca6n/+Z55JvsiGEyILuRNbEwV6IyHW3HhFWV4e
# oLOmdiZnln0aW4mNqIlwp9W9YJcbeyrbpBqwu4EIRwjCw8CALJ9Ve5/ZkRIYxorK
# ByNtY3RbaYjB6zh0TqTXRKV5GNxB50hGdw5FmbiZEXcW9yPheIo173/waDDDPAQi
# keBxu81m9UMGhEb2NxENKX9YNJ1G
# SIG # End signature block
