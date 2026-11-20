#Requires -Version 7
<#
.SYNOPSIS
    Writes catalog/services.json: every service and helper version Djoser may download, with the
    SHA-256 of each file.

.DESCRIPTION
    Versions are listed here by hand, then pinned. Where the vendor publishes a SHA-256, the script
    reads it instead of downloading the file:
      - GitHub releases: the asset's digest
      - MariaDB: the downloads.mariadb.org API
      - PostgreSQL (EnterpriseDB) and MongoDB: the .sha256 file beside each zip
      - MongoDB Database Tools: release.json
    MySQL publishes only MD5 and an Oracle signature. A new MySQL zip is downloaded once, accepted
    only when gpg verifies its signature against Oracle's key (pinned fingerprint below), then
    hashed. gpg comes with Git for Windows.
    A version already in catalog/services.json at the same address keeps its hash. When the vendor
    publishes a different one, the script stops, since the file has changed.

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
    mariadb = @('10.11.20', '11.4.14', '11.8.10', '12.3.4', '13.0.2') | ForEach-Object {
        @{ version = $_; url = "https://archive.mariadb.org/mariadb-$_/winx64-packages/mariadb-$_-winx64.zip" }
    }
    # EnterpriseDB publishes no checksum for these zips: the hash pinned here is of the first download.
    postgres = @('15.20', '16.16', '17.12', '18.7') | ForEach-Object {
        @{ version = $_; url = "https://get.enterprisedb.com/postgresql/postgresql-$_-1-windows-x64-binaries.zip" }
    }
    mongodb = @('7.0.48', '8.0.38', '8.2.12', '8.3.17') | ForEach-Object {
        @{ version = $_; url = "https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-$_.zip" }
    }
    mongosh = @(
        @{ version = '2.14.3'; url = 'https://github.com/mongodb-js/mongosh/releases/download/v2.14.3/mongosh-2.14.3-win32-x64.zip' }
    )
    'mongodb-tools' = @(
        @{ version = '100.20.1'; url = 'https://fastdl.mongodb.org/tools/db/mongodb-database-tools-windows-x86_64-100.20.1.zip' }
    )
    redis = @('7.2.16', '7.4.11', '8.4.7', '8.10.3') | ForEach-Object {
        @{ version = $_; url = "https://github.com/redis-windows/redis-windows/releases/download/$_/Redis-$_-Windows-x64-msys2.zip" }
    }
    rustfs = @(
        @{ version = '1.0.6'; url = 'https://github.com/rustfs/rustfs/releases/download/1.0.6/rustfs-windows-x86_64-v1.0.6.zip' }
    )
    mailpit = @(
        @{ version = '1.33.1'; url = 'https://github.com/axllent/mailpit/releases/download/v1.33.1/mailpit-windows-amd64.zip' }
        @{ version = '1.34.0'; url = 'https://github.com/axllent/mailpit/releases/download/v1.34.0/mailpit-windows-amd64.zip' }
    )
    cloudflared = @(
        @{ version = '2026.11.1'; url = 'https://github.com/cloudflare/cloudflared/releases/download/2026.11.1/cloudflared-windows-amd64.exe' }
    )
    heidisql = @(
        @{ version = '12.22'; url = 'https://github.com/HeidiSQL/HeidiSQL/releases/download/v12.22/HeidiSQL_12.22_64_Portable.zip' }
    )
}

$oracleKeyUrl = 'https://repo.mysql.com/RPM-GPG-KEY-mysql-2023'
$oracleFingerprint = 'BCA43417C3B485DD128EC6D4B7B3B788A8D3785C'

$existing = if (Test-Path $catalog) { Get-Content $catalog -Raw | ConvertFrom-Json } else { $null }

$scratch = Join-Path ([IO.Path]::GetTempPath()) ("services-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $scratch | Out-Null

function Invoke-Retry([scriptblock] $Action) {
    for ($attempt = 1; ; $attempt++) {
        try { return & $Action }
        catch { if ($attempt -ge 4) { throw }; Start-Sleep -Seconds (5 * $attempt) }
    }
}

$script:toolsRelease = $null
# The SHA-256 the vendor publishes for this file, or $null when it publishes none.
function Get-PublishedHash($Release) {
    $url = $Release.url
    $leaf = ($url -split '/')[-1]
    if ($url -match '^https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/([^/]+)$') {
        $owner, $repo, $tag, $asset = $Matches[1], $Matches[2], $Matches[3], $Matches[4]
        $published = Invoke-Retry { Invoke-RestMethod "https://api.github.com/repos/$owner/$repo/releases/tags/$tag" -Headers @{ 'User-Agent' = 'djoser-catalog' } }
        $digest = ($published.assets | Where-Object name -eq $asset | Select-Object -First 1).digest
        if ($digest -match '^sha256:([0-9a-f]{64})$') { return $Matches[1] }
        return $null
    }
    if ($url -like 'https://archive.mariadb.org/*') {
        $data = Invoke-Retry { Invoke-RestMethod "https://downloads.mariadb.org/rest-api/mariadb/$($Release.version)/" }
        $file = $data.release_data.PSObject.Properties.Value.files | Where-Object file_name -eq $leaf | Select-Object -First 1
        return $file.checksum.sha256sum
    }
    if ($url -like 'https://get.enterprisedb.com/*' -or $url -like 'https://fastdl.mongodb.org/windows/*') {
        $text = Invoke-Retry { (Invoke-WebRequest -UseBasicParsing "$url.sha256").Content }
        if ($text -is [byte[]]) { $text = [Text.Encoding]::ASCII.GetString($text) }
        return ($text.Trim() -split '\s+')[0]
    }
    if ($url -like 'https://fastdl.mongodb.org/tools/db/*') {
        if (-not $script:toolsRelease) { $script:toolsRelease = Invoke-Retry { Invoke-RestMethod 'https://downloads.mongodb.org/tools/db/release.json' } }
        return ($script:toolsRelease.versions.downloads.archive | Where-Object url -eq $url | Select-Object -First 1).sha256
    }
    return $null
}

# Throws unless the file's .asc signature verifies against Oracle's pinned key.
function Assert-OracleSignature([string] $File, [string] $Url) {
    $gpg = (Get-Command gpg -ErrorAction SilentlyContinue).Source
    if (-not $gpg) { $gpg = Join-Path $env:ProgramFiles 'Git\usr\bin\gpg.exe' }
    if (-not (Test-Path $gpg)) { throw 'gpg is needed to check a MySQL signature; it comes with Git for Windows.' }
    $gnupgHome = Join-Path $scratch 'gnupg'
    New-Item -ItemType Directory -Force -Path $gnupgHome | Out-Null
    $key = Join-Path $scratch 'oracle.asc'
    Invoke-Retry { Invoke-WebRequest -UseBasicParsing $oracleKeyUrl -OutFile $key }
    Invoke-Retry { Invoke-WebRequest -UseBasicParsing "$Url.asc" -OutFile "$File.asc" }
    & $gpg --homedir $gnupgHome --batch --quiet --import $key 2>$null
    $status = & $gpg --homedir $gnupgHome --batch --status-fd 1 --verify "$File.asc" $File 2>$null
    $valid = $status | Where-Object { $_ -like '`[GNUPG:`] VALIDSIG *' } | Select-Object -First 1
    if (-not $valid -or ($valid -split ' ')[-1] -ne $oracleFingerprint) {
        throw "The Oracle signature of $Url did not verify against $oracleFingerprint."
    }
}

$services = [ordered]@{}
try {
    foreach ($name in $releases.Keys) {
        $versions = [ordered]@{}
        foreach ($release in $releases[$name]) {
            $label = "$name $($release.version)"
            $known = if ($existing -and $existing.services.$name) { $existing.services.$name.versions.($release.version) }
            $published = Get-PublishedHash $release
            if ($published) { $published = $published.ToLowerInvariant() }
            if ($known -and $known.url -eq $release.url) {
                if ($published -and $published -ne $known.sha256) {
                    throw "${label}: the vendor now publishes $published, but the catalog pins $($known.sha256). The file has changed; check it before trusting it."
                }
                $versions[$release.version] = [ordered]@{ url = $known.url; sha256 = $known.sha256 }
                continue
            }
            if ($published -match '^[0-9a-f]{64}$') {
                $versions[$release.version] = [ordered]@{ url = $release.url; sha256 = $published }
                Write-Host "$label $published (published)"
                continue
            }
            $file = Join-Path $scratch 'download'
            Invoke-Retry { Invoke-WebRequest -UseBasicParsing $release.url -OutFile $file }
            $how = 'downloaded'
            if ($release.url -like 'https://cdn.mysql.com/*') {
                Assert-OracleSignature $file $release.url
                $how = 'downloaded, Oracle signature verified'
            }
            $hash = (Get-FileHash $file -Algorithm SHA256).Hash.ToLowerInvariant()
            Remove-Item $file, "$file.asc" -ErrorAction SilentlyContinue
            $versions[$release.version] = [ordered]@{ url = $release.url; sha256 = $hash }
            Write-Host "$label $hash ($how)"
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
