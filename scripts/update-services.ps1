#Requires -Version 7
<#
.SYNOPSIS
    Writes catalog/services.json: every service and helper version Djoser may download, with the
    SHA-256 of each file.

.DESCRIPTION
    Versions are listed here by hand, then pinned. A version already in catalog/services.json at the
    same address keeps its hash and is not downloaded again; a new one is downloaded once and hashed.

.EXAMPLE
    pwsh scripts/update-services.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$catalog = Join-Path (Split-Path -Parent $PSScriptRoot) 'catalog/services.json'

$releases = [ordered]@{
    mysql = @(
        @{ version = '8.0.46'; url = 'https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-8.0.46-winx64.zip' }
        @{ version = '8.4.13'; url = 'https://cdn.mysql.com/Downloads/MySQL-8.4/mysql-8.4.13-winx64.zip' }
        @{ version = '9.7.4'; url = 'https://cdn.mysql.com/Downloads/MySQL-9.7/mysql-9.7.4-winx64.zip' }
    )
    redis = @('7.2.16', '7.4.11', '8.4.7', '8.10.3') | ForEach-Object {
        @{ version = $_; url = "https://github.com/redis-windows/redis-windows/releases/download/$_/Redis-$_-Windows-x64-msys2.zip" }
    }
    cloudflared = @(
        @{ version = '2026.10.7'; url = 'https://github.com/cloudflare/cloudflared/releases/download/2026.10.7/cloudflared-windows-amd64.exe' }
    )
    heidisql = @(
        @{ version = '12.22'; url = 'https://github.com/HeidiSQL/HeidiSQL/releases/download/v12.22/HeidiSQL_12.22_64_Portable.zip' }
    )
}

$existing = if (Test-Path $catalog) { Get-Content $catalog -Raw | ConvertFrom-Json } else { $null }

$scratch = Join-Path ([IO.Path]::GetTempPath()) ("services-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $scratch | Out-Null

$services = [ordered]@{}
try {
    foreach ($name in $releases.Keys) {
        $versions = [ordered]@{}
        foreach ($release in $releases[$name]) {
            $known = if ($existing -and $existing.services.$name) { $existing.services.$name.versions.($release.version) }
            if ($known -and $known.url -eq $release.url) {
                $versions[$release.version] = [ordered]@{ url = $known.url; sha256 = $known.sha256 }
                continue
            }
            $file = Join-Path $scratch 'download'
            for ($attempt = 1; ; $attempt++) {
                try { Invoke-WebRequest -UseBasicParsing $release.url -OutFile $file; break }
                catch { if ($attempt -ge 4) { throw }; Start-Sleep -Seconds (5 * $attempt) }
            }
            $hash = (Get-FileHash $file -Algorithm SHA256).Hash.ToLowerInvariant()
            Remove-Item $file
            $versions[$release.version] = [ordered]@{ url = $release.url; sha256 = $hash }
            Write-Host "$name $($release.version) $hash"
        }
        $services[$name] = [ordered]@{ versions = $versions }
    }
}
finally {
    Remove-Item -Recurse -Force $scratch -ErrorAction SilentlyContinue
}

$json = [ordered]@{ schema = 1; services = $services } | ConvertTo-Json -Depth 8
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $catalog) | Out-Null
[IO.File]::WriteAllText($catalog, $json.Replace("`r`n", "`n") + "`n", [Text.UTF8Encoding]::new($false))
Write-Host "Wrote $catalog"
