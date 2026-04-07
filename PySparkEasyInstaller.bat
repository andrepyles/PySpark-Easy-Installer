<# :
@echo off
TITLE PySpark Easy Installer

:: 1. Check Admin Privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Admin Privileges...
    :: If not admin, restart to request for Admin privileges
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: 2. If already admin, run PowerShell script
powershell -NoExit -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content '%~f0') -join [Environment]::NewLine)"
exit /b
#>

# =====================================================================
# POWERSHELL SCRIPT STARTS HERE
# =====================================================================
Write-Host "Starting Installation" -ForegroundColor Green

# 1. Get the LATEST versions dynamically
Write-Host "Fetching the latest PySpark version from PyPI..." -ForegroundColor Yellow
$pypiResponse = Invoke-RestMethod -Uri "https://pypi.org/pypi/pyspark/json"
$sparkVersion = $pypiResponse.info.version
Write-Host "Latest Spark version detected: $sparkVersion" -ForegroundColor Green

$sparkUrl = "https://archive.apache.org/dist/spark/spark-$sparkVersion/spark-$sparkVersion-bin-hadoop3.tgz"
$winutilsUrl = "https://raw.githubusercontent.com/kontext-tech/winutils/refs/heads/master/hadoop-3.4.0-win10-x64/bin/winutils.exe"
$hadoopDllUrl = "https://raw.githubusercontent.com/kontext-tech/winutils/refs/heads/master/hadoop-3.4.0-win10-x64/bin/hadoop.dll"
# UPDATED: Microsoft OpenJDK 17 Windows x64 zip permalink
$javaUrl = "https://aka.ms/download-jdk/microsoft-jdk-17-windows-x64.zip" 

# Destination directories
$baseDir = "C:\"
$sparkDir = Join-Path $baseDir "spark"
$hadoopDir = Join-Path $baseDir "hadoop"
$hadoopBinDir = Join-Path $hadoopDir "bin"
$javaDir = Join-Path $baseDir "java"

# 2. Clean existing folders and create new structure
Write-Host "Cleaning up old directories and creating new ones in C:\..." -ForegroundColor Yellow
if (Test-Path $sparkDir) { Remove-Item -Path $sparkDir -Recurse -Force }
if (Test-Path $hadoopDir) { Remove-Item -Path $hadoopDir -Recurse -Force }
if (Test-Path $javaDir) { Remove-Item -Path $javaDir -Recurse -Force }

New-Item -ItemType Directory -Force -Path $sparkDir | Out-Null
New-Item -ItemType Directory -Force -Path $hadoopBinDir | Out-Null
New-Item -ItemType Directory -Force -Path $javaDir | Out-Null

# 3. Download and extract Java JDK 17
$javaZip = "$env:TEMP\jdk17.zip"
Write-Host "Downloading Java JDK 17..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $javaUrl -OutFile $javaZip
Write-Host "Extracting Java JDK 17..." -ForegroundColor Yellow
tar -xf $javaZip -C $javaDir
$javaExtractedFolder = Get-ChildItem -Path $javaDir -Directory | Select-Object -First 1
$javaHomePath = $javaExtractedFolder.FullName

# 4. Download and extract Apache Spark (Latest)
$sparkTar = "$env:TEMP\spark.tgz"
Write-Host "Downloading Apache Spark $sparkVersion..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $sparkUrl -OutFile $sparkTar
Write-Host "Extracting Spark..." -ForegroundColor Yellow
tar -xvzf $sparkTar -C $sparkDir
$sparkExtractedFolder = Get-ChildItem -Path $sparkDir -Directory | Select-Object -First 1
$sparkHomePath = $sparkExtractedFolder.FullName

# 5. Download Winutils
Write-Host "Downloading winutils.exe and hadoop.dll..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $winutilsUrl -OutFile (Join-Path $hadoopBinDir "winutils.exe")
Invoke-WebRequest -Uri $hadoopDllUrl -OutFile (Join-Path $hadoopBinDir "hadoop.dll")

# 6. Configure Environment Variables
Write-Host "Configuring JAVA_HOME and updating system PATH..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHomePath, "Machine")

$oldPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$sparkBin = Join-Path $sparkHomePath "bin"
$hadoopBin = Join-Path $hadoopDir "bin"
$javaBin = Join-Path $javaHomePath "bin"

$newPath = $oldPath
if ($newPath -notmatch [regex]::Escape($sparkBin)) { $newPath = "$newPath;$sparkBin" }
if ($newPath -notmatch [regex]::Escape($hadoopBin)) { $newPath = "$newPath;$hadoopBin" }
if ($newPath -notmatch [regex]::Escape($javaBin)) { $newPath = "$newPath;$javaBin" }

if ($newPath -ne $oldPath) {
    [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
    Write-Host "PATH updated successfully!" -ForegroundColor Green
}

# 7. Install PySpark via PIP
Write-Host "Installing pyspark (latest) and findspark libraries via pip..." -ForegroundColor Yellow
pip install --upgrade pyspark==$sparkVersion findspark

Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "INSTALLATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "1. Java JDK 17 installed at: $javaHomePath" -ForegroundColor White
Write-Host "2. Spark ($sparkVersion) installed at: $sparkHomePath" -ForegroundColor White
Write-Host "3. Hadoop (winutils) installed at: $hadoopDir" -ForegroundColor White
Write-Host "WARNING: Please close this terminal and open a new one to apply the new variables." -ForegroundColor Red
Write-Host "=====================================================================" -ForegroundColor Green
