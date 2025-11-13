<#
PowerShell helper to expunge a blob from a git repo using git-filter-repo.
Requires git-filter-repo installed (pip install git-filter-repo) and Python available in PATH.
This script creates a local --bare mirror, runs git-filter-repo to remove the blob, and shows verification steps.

USAGE: .\expunge_blob.ps1 -BlobId <blob-sha> -RepoUrl <repo-ssh-or-https> [-BackupDir <path>]
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$BlobId,

    [Parameter(Mandatory=$true)]
    [string]$RepoUrl,

    [string]$BackupDir = "$env:TEMP\git-expunge-backup"
)

$ErrorActionPreference = 'Stop'

Write-Host "Preparing mirror clone in $BackupDir"
if (Test-Path $BackupDir) {
    Write-Host "Removing existing backup at $BackupDir"
    Remove-Item -Recurse -Force $BackupDir
}
New-Item -ItemType Directory -Path $BackupDir | Out-Null

Push-Location $BackupDir
try {
    Write-Host "Cloning mirror..."
    git clone --mirror $RepoUrl repo-mirror.git
    Push-Location repo-mirror.git

    Write-Host "Verifying blob presence..."
    $found = git rev-list --objects --all | Select-String $BlobId -SimpleMatch
    if ($found) {
        Write-Host "Blob found in the mirror. Proceeding with git-filter-repo to remove it."
    } else {
        Write-Host "Blob not found in this mirror. Exiting."
        exit 1
    }

    Write-Host "Running git-filter-repo to remove blob: $BlobId"
    # Ensure git-filter-repo is available (pip install git-filter-repo)
    # The recommended way to remove a blob by id is to create a file with blob ids to remove
    $blobFile = "blobs-to-remove.txt"
    Set-Content -Path $blobFile -Value $BlobId

    # Run git-filter-repo to remove blobs listed in the file
    # Note: git-filter-repo will rewrite history and change commit SHAs.
    git filter-repo --strip-blobs-with-ids $blobFile

    Write-Host "Verification after rewrite. Listing refs referencing the blob (should be none):"
    git rev-list --objects --all | Select-String $BlobId -SimpleMatch | ForEach-Object { Write-Host $_ }

    Write-Host "If verification looks good, coordinate with repo admins. To push rewritten refs run:"
    Write-Host "  git push --force --all origin"
    Write-Host "  git push --force --tags origin"

} finally {
    Pop-Location
    Pop-Location
}

Write-Host "Done"
