#Requires -Version 7
<#
.SYNOPSIS
    Writes catalog/extensions.json: the PHP extensions Djoser may download for each PHP minor, with
    the SHA-256 of each file.

.DESCRIPTION
    Builds come from the PHP for Windows PECL folder, which publishes no hashes, so the hash recorded
    here is the check Djoser applies later. A build already in catalog/extensions.json at the same
    address keeps its hash and is not downloaded again.

.EXAMPLE
    pwsh scripts/update-extensions.ps1
    pwsh scripts/update-extensions.ps1 -PhpMinors 8.3, 8.4, 8.5
#>
[CmdletBinding()]
param(
    [string[]] $PhpMinors = @('8.2', '8.3', '8.4', '8.5')
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$base = 'https://downloads.php.net/~windows/pecl/releases'
$catalog = Join-Path (Split-Path -Parent $PSScriptRoot) 'catalog/extensions.json'

$table = [ordered]@{
    redis      = @{ zend = $false; needs = '' }
    imagick    = @{ zend = $false; needs = '' }
    memcached  = @{ zend = $false; needs = '' }
    xdebug     = @{ zend = $true;  needs = '' }
    sqlsrv     = @{ zend = $false; needs = 'sqlsrv needs the Microsoft ODBC Driver for SQL Server on this machine' }
    pdo_sqlsrv = @{ zend = $false; needs = 'pdo_sqlsrv needs the Microsoft ODBC Driver for SQL Server on this machine' }
    apcu       = @{ zend = $false; needs = '' }
    mongodb    = @{ zend = $false; needs = '' }
    amqp       = @{ zend = $false; needs = '' }
}

function Get-Stable([string] $Name) {
    $links = (Invoke-WebRequest -UseBasicParsing "$base/$Name/").Links.href
    $versions = foreach ($link in $links) {
        $leaf = ($link.TrimEnd('/') -split '/')[-1]
        if ($leaf -match '^\d+(\.\d+)+$') { $leaf }
    }
    return @($versions | Sort-Object { [version]$_ } -Descending)
}

$existing = if (Test-Path $catalog) { Get-Content $catalog -Raw | ConvertFrom-Json } else { $null }

$scratch = Join-Path ([IO.Path]::GetTempPath()) ("extensions-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $scratch | Out-Null

$extensions = [ordered]@{}
try {
    foreach ($name in $table.Keys) {
        $versions = Get-Stable $name
        $builds = [ordered]@{}
        foreach ($minor in $PhpMinors) {
            foreach ($version in $versions) {
                $listing = (Invoke-WebRequest -UseBasicParsing "$base/$name/$version/").Links.href
                $file = @($listing | ForEach-Object { ($_ -split '/')[-1] } | Where-Object { $_ -match "^php_$name-.*-$([regex]::Escape($minor))-nts-vs1[67]-x64\.zip$" }) | Select-Object -First 1
                if (-not $file) { continue }

                $url = "$base/$name/$version/$file"
                $known = if ($existing -and $existing.extensions.$name) { $existing.extensions.$name.builds.$minor }
                if ($known -and $known.url -eq $url) {
                    $hash = $known.sha256
                } else {
                    $zip = Join-Path $scratch $file
                    for ($attempt = 1; ; $attempt++) {
                        try { Invoke-WebRequest -UseBasicParsing $url -OutFile $zip; break }
                        catch { if ($attempt -ge 4) { throw }; Start-Sleep -Seconds (5 * $attempt) }
                    }
                    $hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant()
                    Remove-Item $zip
                    Write-Host "$name $version for PHP $minor $hash"
                }
                $builds[$minor] = [ordered]@{ version = $version; url = $url; sha256 = $hash }
                break
            }
        }
        $extensions[$name] = [ordered]@{ zend = $table[$name].zend; needs = $table[$name].needs; builds = $builds }
    }
}
finally {
    Remove-Item -Recurse -Force $scratch -ErrorAction SilentlyContinue
}

$json = [ordered]@{ schema = 1; extensions = $extensions } | ConvertTo-Json -Depth 8
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $catalog) | Out-Null
[IO.File]::WriteAllText($catalog, $json.Replace("`r`n", "`n") + "`n", [Text.UTF8Encoding]::new($false))
Write-Host "Wrote $catalog"
