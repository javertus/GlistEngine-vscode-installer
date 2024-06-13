#INSTALLER SCRIPT FOR GLIST ENGINE
#YOU CAN ALSO RUN THIS SCRIPT FOR UNINSTALLING AND REINSTALLING THE GLIST ENGINE

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Create-Shortcut {
    param (
        [string]$exePath
    )

$shell = New-Object -ComObject WScript.Shell

# Create a shortcut object
$desktopPath = ([System.Environment]::GetFolderPath('Desktop'))
$shortcutName = "Glist Engine.lnk"
$shortcut = $shell.CreateShortcut("$desktopPath\$shortcutName")

# Set properties of the shortcut
$shortcut.TargetPath = $exePath
$shortcut.WorkingDirectory = (Split-Path $exePath -Parent)

$shortcut.Save()
}

function Extract-Archive {
    param (
        [string]$InputDir,
        [string]$OutputDir,
        [string]$Message = "Successfully Extracted"
    )

    try {
    #Extract the archive
    [System.IO.Compression.ZipFile]::ExtractToDirectory($InputDir, $OutputDir)
    Write-Host $Message
    } 
    catch {
    Write-Host "Extracting failed!"
    }
}

#Might be a helpfull method in future.
function Get-UserInput {
    param (
        [string]$Prompt = "Please enter yes or no"
    )

    while ($true) {
        $input = Read-Host -Prompt $Prompt
        if ($input -match '^(yes)$') {
            return $true
        }
		elseif($input -match '^(no)$') {
			return $false
		}
		else {
            Write-Host "Invalid input. Please enter 'yes' or 'no'."
        }
    }
}

function Get-RedirectUrl {
    param (
        [string]$url
    )

    $request = [System.Net.WebRequest]::Create($url)
    $request.AllowAutoRedirect = $false

    try {
        $response = $request.GetResponse()
        if ($response.StatusCode -eq "302" -or $response.StatusCode -eq "301") {
            $finalUrl = $response.Headers["Location"]
            $response.Close()
            Write-Output $finalUrl
        } else {
            Write-Output $url
        }
    } catch {
        Write-Host "Error: $_.Exception.Message"
    }
}

$temp_dir = "$env:TEMP\GlistVSCodeInstaller"
$glistzbin_dir = "C:\dev\glist\zbin\glistzbin-win64"
$glistengine_dir = "C:\dev\glist"
$glistapps_dir = "C:\dev\glist\myglistapps"
$glistplugins_dir = "C:\dev\glist\myglistplugins"
$glistengine_url = Get-RedirectUrl -url "https://codeload.github.com/GlistEngine/GlistEngine/zip/refs/heads/main"
$glistapp_url = Get-RedirectUrl -url "https://codeload.github.com/javertus/GlistApp-vscode/zip/refs/heads/main"
$glist_clang_url = Get-RedirectUrl -url "https://github.com/javertus/glistzbin-win64-vscode/releases/download/Dependencies/clang64.zip"
$glist_cmake_url = Get-RedirectUrl -url "https://github.com/javertus/glistzbin-win64-vscode/releases/download/Dependencies/CMake.zip"
$vscode_installation_url = Get-RedirectUrl -url "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-archive"
$vscode_extension_url = "https://raw.githubusercontent.com/javertus/glistzbin-win64/main/glist-engine-worker-extension-0.0.1.vsix"

#Create glistplugins dir
New-Item -ItemType Directory -Path $glistplugins_dir -Force -ErrorAction Inquire | Out-Null

#Create temp dir
Remove-Item -Path $temp_dir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $temp_dir -Force -ErrorAction Inquire | Out-Null

Write-Host "Installing Glist Engine dependencies..."

#Install Glist Engine
Write-Host "Installing Engine"
Start-BitsTransfer -Source $glistengine_url -Destination "$temp_dir\GlistEngine.zip" -ErrorAction Inquire
Remove-Item -Path "$glistengine_dir\GlistEngine" -Recurse -Force -ErrorAction SilentlyContinue
Extract-Archive -InputDir "$temp_dir\GlistEngine.zip" -OutputDir $glistengine_dir -Message "Engine Installed."
Rename-Item -Path "$glistengine_dir\GlistEngine-main" -NewName "GlistEngine"

#Install Clang
Write-Host "Installing Clang Binaries"
Start-BitsTransfer -Source $glist_clang_url -Destination "$temp_dir\clang64.zip" -ErrorAction Inquire
Remove-Item -Path "$glistzbin_dir\clang64" -Recurse -Force -ErrorAction SilentlyContinue
Extract-Archive -InputDir "$temp_dir\clang64.zip" -OutputDir $glistzbin_dir -Message "Clang Binaries Installed."

#Install CMake
Write-Host "Installing Cmake"
Start-BitsTransfer -Source $glist_cmake_url -Destination "$temp_dir\CMake.zip" -ErrorAction Inquire
Remove-Item -Path "$glistzbin_dir\CMake" -Recurse -Force -ErrorAction SilentlyContinue
Extract-Archive -InputDir "$temp_dir\CMake.zip" -OutputDir $glistzbin_dir -Message "CMake Binaries Installed."

#Create Empty GlistApp
Write-Host "Creating Empty GlistApp"
Start-BitsTransfer -Source $glistapp_url -Destination "$temp_dir\GlistApp.zip" -ErrorAction Inquire
Rename-Item -Path "$glistapps_dir\GlistApp" -NewName "GlistAppOld" -Force -ErrorAction SilentlyContinue
Extract-Archive -InputDir "$temp_dir\GlistApp.zip" -OutputDir $glistapps_dir -Message "GlistApp Installed."
Rename-Item -Path "$glistapps_dir\GlistApp-vscode-main" -NewName "GlistApp"

# Check for VS Code installation
$check_installation =  (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  Where-Object {$_.DisplayName -like "*Visual Studio Code*"})
if($check_installation) {
    Write-Host "Visual Studio Code installation found at" $check_installation.DisplayIcon 
    Write-Host "Skipping Visual Studio Code installation."

    #Install Glist Engine Extension
    Write-Host "Installing Glist Engine VS Code Worker Extension"
    Start-BitsTransfer -Source $vscode_extension_url -Destination "$temp_dir\glistextension.vsix" -ErrorAction Inquire
    $location = $check_installation.'Inno Setup: App Path'
    Start-Process -FilePath "$location\bin\code" -ArgumentList "--install-extension $temp_dir\glistextension.vsix"
}
else {
    #Install VS Code
    Write-Host "Visual Studio Code is not found. Installing Visual Studio Code to:" $vscode_location
    Start-BitsTransfer -Source $vscode_installation_url -Destination "$temp_dir\vscode.zip" -ErrorAction Inquire
    Remove-Item -Path $vscode_dir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $vscode_dir -Force -ErrorAction Inquire | Out-Null
    Extract-Archive -InputDir "$temp_dir\vscode.zip" -OutputDir "$glistzbin_dir\Microsoft VS Code" -Message "Visual Studio Code installed successfully."
    Create-Shortcut -exePath $vscode_dir\Code.exe
    
    #Install Glist Engine Extension
    Write-Host "Installing Glist Engine VS Code Worker Extension"
    Start-BitsTransfer -Source $vscode_extension_url -Destination "$temp_dir\glistextension.vsix" -ErrorAction Inquire
    Start-Process -FilePath "$vscode_dir\bin\code" -ArgumentList "--install-extension $temp_dir\glistextension.vsix"
}

#Add cmake to system path
$newPath = "C:\dev\glist\zbin\gliszbin-win64\CMake\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -notlike "*$newPath*") {
    # If the path doesn't exist, add it
    $newPath = $currentPath + ";" + $newPath
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
}

Write-Host "Glist Engine installation complete! After launching VS Code, please wait until VS Code's first launch complete!!!"