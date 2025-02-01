cls
$PluginName = "Gitmoji"

# Task 1: Project compilation and publication
Write-Host "✅ 1. Starting project publication for plugin $PluginName..." -ForegroundColor Cyan

try {
    # Build the full path to the .csproj project file (relative to the script's location)
    $projectPath = Join-Path $PSScriptRoot "Flow.Launcher.Plugin.Gitmoji\Flow.Launcher.Plugin.Gitmoji.csproj"
    
    # Check if the project file exists
    if (-Not (Test-Path $projectPath)) {
        throw "❌ Project file $projectPath not found."
    }

    # Execute the dotnet publish command and check if it succeeds
    dotnet publish $projectPath -c Debug -r win-x64 --no-self-contained
    if ($LASTEXITCODE -ne 0) {
        throw "❌ Project publication failed with exit code $LASTEXITCODE."
    }
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}

# Define the publish path (the publish output is generated inside the project folder)
$publishPath = Join-Path $PSScriptRoot "Flow.Launcher.Plugin.Gitmoji\bin\Debug\win-x64\publish"

# Verify that the publish folder exists
if (-Not (Test-Path $publishPath)) {
    Write-Host "❌ Publish folder $publishPath not found." -ForegroundColor Red
    exit 1
}

# Define necessary paths
$AppDataFolder = [Environment]::GetFolderPath("ApplicationData")
$flowLauncherExe = "$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe"

# Task 2: Check for the presence of Flow Launcher
if (Test-Path $flowLauncherExe) {
    Write-Host "✅ 2. Flow Launcher found. Stopping the application..." -ForegroundColor Cyan
    
    # Stop the Flow Launcher process if it is running
    if (Get-Process -Name "Flow.Launcher" -ErrorAction SilentlyContinue) {
        Stop-Process -Name "Flow.Launcher" -Force
        Start-Sleep -Seconds 2
    }

    # Define the plugin destination path
    $pluginPath = Join-Path $AppDataFolder "FlowLauncher\Plugins\$PluginName"
    
    # Task 3: Remove the old version of the plugin
    if (Test-Path $pluginPath) {
        Write-Host "✅ 3. Removing the old version of plugin $PluginName..." -ForegroundColor Cyan
        Remove-Item -Recurse -Force $pluginPath
    } else {
        Write-Host "✅ 3. No old version of plugin $PluginName found." -ForegroundColor Cyan
    }

    # Task 4: Copy the new published files to the plugins folder
    Write-Host "✅ 4. Copying the published files to the plugins folder..." -ForegroundColor Cyan
    $destinationFolder = Join-Path $AppDataFolder "FlowLauncher\Plugins"
    Copy-Item $publishPath $destinationFolder -Recurse -Force
    
    # Rename the copied folder ("publish") to $PluginName.
    $copiedFolder = Join-Path $destinationFolder "publish"
    if (Test-Path $copiedFolder) {
        Rename-Item -Path $copiedFolder -NewName $PluginName
    } else {
        Write-Host "❌ Error: Expected folder $copiedFolder not found." -ForegroundColor Red
        exit 1
    }

    # Task 5: Restart Flow Launcher
    Write-Host "✅ 5. Restarting Flow Launcher..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    Start-Process $flowLauncherExe
    Write-Host "✅ 6. Update and restart successful!" -ForegroundColor Cyan
} else {
    Write-Host "❌ Error: Flow.Launcher.exe not found. Please install Flow Launcher first." -ForegroundColor Red
}
