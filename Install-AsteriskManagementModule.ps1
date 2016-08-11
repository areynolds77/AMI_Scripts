param([string]$InstallDirectory)

$filelist = echo `
    AsteriskManagementModule.psd1 `
    AsteriskManagementModule.psm1 `
    Initialize-Call.ps1

if ('' -eq $InstallDirectory) {
    $personalModules = Join-Path -Path ([System.Environment]::GetFolderPath('MyDocuments')) -ChildPath WindowsPowershell\Modules

    if(($env:PSModulePath -split ';') -notcontains $personalModules) {
        Write-Warning "personalModules is not in `$env:PSModulePath"
    }

    if(!(Test-Path $personalModules)) {
        Write-Warning "$personalModules does not exist."
    }

    $InstallDirectory = Join-Path -Path $personalModules -ChildPath AsteriskManagementModule
}

if (!(Test-Path $InstallDirectory)) {
    $null = mkdir $InstallDirectory
}

$wc = New-Object System.Net.WebClient
$filelist | ForEach-Object {
    $wc.DownloadFile("https://raw.github.com/areynolds77/AMI_Scripts/master/$_","$InstallDirectory\$_")
}
    