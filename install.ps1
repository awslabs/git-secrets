Param([string]$InstallationDirectory = $($Env:USERPROFILE + "\.git-secrets"))

Write-Host "Checking to see if installation directory already exists..."
if (-not (Test-Path $InstallationDirectory))
{
    Write-Host "Creating installation directory."
    New-Item -ItemType Directory -Path $InstallationDirectory | Out-Null
}
else
{
    Write-Host "Installation directory already exists."
}

Write-Host "Copying files."
Copy-Item ./git-secrets -Destination $InstallationDirectory -Force
Copy-Item ./git-secrets.1 -Destination $InstallationDirectory -Force

Write-Host "Checking if directory already exists in Path..."
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$InstallationDirectory*")
{
    Write-Host "Adding to path."
    $newPath = $currentPath
    if(-not ($newPath.EndsWith(";")))
    {
        $newPath = $newPath + ";"
    }
    $newPath = $newPath + $InstallationDirectory
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
}
else
{
    Write-Host "Already in Path."
}

# Adding to Session
Write-Host "Adding to user session."
$currentSessionPath = $Env:Path
if ($currentSessionPath -notlike "*$InstallationDirectory*")
{
    if(-not ($currentSessionPath.EndsWith(";")))
    {
        $currentSessionPath = $currentSessionPath + ";"
    }
    $Env:Path = $currentSessionPath + $InstallationDirectory
}

Write-Host "Done."