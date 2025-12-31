# --- Paths and settings ---
#This PowerShell script automates the backup process for a VMware Workstation virtual machine on Windows.

$vmrun = "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"  # ----> Change to your own path to this file if needed
$vmx = "C:\Users\Yehor\Documents\Virtual Machines\Debian 12.x 64-bit\Debian 12.x 64-bit.vmx" # ----> Change to your own path to this file if needed
$vmFolder = "C:\Users\Yehor\Documents\Virtual Machines\Debian 12.x 64-bit" # ----> Change to your own path to this file if needed
$backupDest = "\\DESKTOP-2C3B93R\Test_backup\"  # remote server name
$date = Get-Date -Format "yyyy-MM-dd_HH-mm"
$snapshotName = "backup_$date"
$tempFolder = "C:\Scripts\temp_backup_$date" # ----> Change to your own path to this file if needed
$sevenZip = "C:\Program Files\7-Zip\7z.exe" # ----> Change to your own path to this file if needed
$tempZip = "$tempFolder\$date.7z"
$finalZip = "$backupDest\$date.7z"

# --- 1. Create snapshot ---
Write-Output "Creating VM snapshot..."
& "$vmrun" snapshot "$vmx" "$snapshotName"
Start-Sleep -Seconds 10

# --- 2. Create temporary folder ---
Write-Output "Creating temporary backup folder..."
New-Item -ItemType Directory -Force -Path $tempFolder

# --- 3. Copy VM files to temporary folder ---
Write-Output "Copying VM files..."
robocopy "$vmFolder" "$tempFolder" /MIR /R:2 /W:5 /Z /FFT /XJ /NP

# --- 4. Create 7-Zip archive ---
Write-Output "Creating 7-Zip archive..."
& "$sevenZip" a -t7z "$tempZip" "$tempFolder\*" -mx=9 -mmt

# --- 5. Delete snapshot ---
Write-Output "Deleting VM snapshot..."
& "$vmrun" deleteSnapshot "$vmx" "$snapshotName"

# --- 6. Move archive to backup server ---
Write-Output "Moving archive to backup destination..."
Copy-Item "$tempZip" "$finalZip" -Force

# --- 7. Clean up temporary files ---
Write-Output "Cleaning up temporary files..."
Remove-Item -Recurse -Force $tempFolder

# --- 8. Backup rotation: keep last 4 archives ---
Write-Output "Rotating old backups..."
Get-ChildItem $backupDest -Filter "*.7z" |
    Sort-Object CreationTime -Descending |
    Select-Object -Skip 4 |
    Remove-Item -Force
