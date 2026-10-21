[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string]$HostLogDirectory,

	[Parameter(Mandatory = $true)]
	[string]$ClientLogDirectory,

	[Parameter(Mandatory = $true)]
	[string]$OutputDirectory,

	[Parameter(Mandatory = $false)]
	[string]$HostModDirectory,

	[Parameter(Mandatory = $false)]
	[string]$ClientModDirectory
)

$ErrorActionPreference = "Stop"
$requiredLogs = @(
	"Database.log",
	"Modding.log",
	"Lua.log"
)
$optionalNetworkLogs = @(
	"GameCore.log",
	"net_connection_debug.log",
	"net_message_debug.log"
)

$hostPath = (Resolve-Path -LiteralPath $HostLogDirectory).Path
$clientPath = (Resolve-Path -LiteralPath $ClientLogDirectory).Path
$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)

if (Test-Path -LiteralPath $outputPath) {
	throw "Output directory already exists; choose a new evidence directory: $outputPath"
}

New-Item -ItemType Directory -Path $outputPath | Out-Null
$missing = @()

foreach ($side in @("host", "client")) {
	$source = if ($side -eq "host") { $hostPath } else { $clientPath }
	$destination = Join-Path $outputPath $side
	New-Item -ItemType Directory -Path $destination | Out-Null

	foreach ($logName in $requiredLogs) {
		$sourceFile = Join-Path $source $logName
		if (Test-Path -LiteralPath $sourceFile -PathType Leaf) {
			Copy-Item -LiteralPath $sourceFile -Destination $destination
		} else {
			$missing += "$side/$logName"
		}
	}
	foreach ($logName in $optionalNetworkLogs) {
		$sourceFile = Join-Path $source $logName
		if (Test-Path -LiteralPath $sourceFile -PathType Leaf) {
			Copy-Item -LiteralPath $sourceFile -Destination $destination
		}
	}
}

function Get-DirectoryManifest([string]$DirectoryPath) {
	$resolved = (Resolve-Path -LiteralPath $DirectoryPath).Path
	Get-ChildItem -LiteralPath $resolved -Recurse -File |
		Sort-Object { $_.FullName.Substring($resolved.Length + 1).Replace("\", "/") } |
		ForEach-Object {
			$relative = $_.FullName.Substring($resolved.Length + 1).Replace("\", "/")
			$hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
			"$hash  $relative"
		}
}

$modComparison = "NotRequested"
if ($HostModDirectory -or $ClientModDirectory) {
	if (-not $HostModDirectory -or -not $ClientModDirectory) {
		throw "Provide both HostModDirectory and ClientModDirectory, or neither."
	}
	$hostModManifest = @(Get-DirectoryManifest $HostModDirectory)
	$clientModManifest = @(Get-DirectoryManifest $ClientModDirectory)
	$hostModManifest | Set-Content -LiteralPath (Join-Path $outputPath "HOST_MOD_SHA256.txt") -Encoding UTF8
	$clientModManifest | Set-Content -LiteralPath (Join-Path $outputPath "CLIENT_MOD_SHA256.txt") -Encoding UTF8
	$modComparison = if (Compare-Object $hostModManifest $clientModManifest) {
		"Different"
	} else {
		"Identical"
	}
}

function Export-LotmGameplayStream([string]$Side) {
	$luaLog = Join-Path (Join-Path $outputPath $Side) "Lua.log"
	$streamPath = Join-Path $outputPath ("LOTM_GAMEPLAY_{0}.txt" -f $Side.ToUpperInvariant())
	$stream = @()
	if (Test-Path -LiteralPath $luaLog) {
		$stream = Get-Content -LiteralPath $luaLog -Encoding UTF8 |
			Where-Object { $_ -match "LOTM_RP_Gameplay: \[LOTM_(RP|PP)\]" } |
			ForEach-Object { ($_ -replace "^.*?LOTM_RP_Gameplay:\s*", "") }
	}
	$stream | Set-Content -LiteralPath $streamPath -Encoding UTF8
	return $stream
}

$hostGameplayStream = @(Export-LotmGameplayStream "host")
$clientGameplayStream = @(Export-LotmGameplayStream "client")
$gameplayComparison = if (Compare-Object $hostGameplayStream $clientGameplayStream) {
	"Different"
} else {
	"Identical"
}

$manifestPath = Join-Path $outputPath "SHA256SUMS.txt"
$summaryPath = Join-Path $outputPath "LOTM_RP_LOG_SUMMARY.txt"
$manifest = Get-ChildItem -LiteralPath $outputPath -Recurse -File |
	Where-Object { $_.FullName -ne $manifestPath -and $_.FullName -ne $summaryPath } |
	Sort-Object FullName |
	ForEach-Object {
		$relative = $_.FullName.Substring($outputPath.Length + 1).Replace("\", "/")
		$hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
		"$hash  $relative"
	}
$manifest | Set-Content -LiteralPath $manifestPath -Encoding UTF8

$summary = @(
	"Red Priest Path dual-client evidence summary",
	"CollectedAtUTC=$([DateTime]::UtcNow.ToString('o'))",
	"HostSource=$hostPath",
	"ClientSource=$clientPath",
	"Missing=$($missing -join ',')",
	"ModFiles=$modComparison",
	"LOTMGameplayStream=$gameplayComparison",
	""
)
foreach ($side in @("host", "client")) {
	$summary += "===== $side ====="
	$luaLog = Join-Path (Join-Path $outputPath $side) "Lua.log"
	if (Test-Path -LiteralPath $luaLog) {
		$matches = Select-String -LiteralPath $luaLog -Pattern "LOTM_RP|LOTM_PP|Runtime Error|desync" |
			ForEach-Object { $_.Line }
		$summary += $matches
	}
	foreach ($networkLogName in $optionalNetworkLogs) {
		$networkLog = Join-Path (Join-Path $outputPath $side) $networkLogName
		if (Test-Path -LiteralPath $networkLog) {
			$networkMatches = Select-String -LiteralPath $networkLog -Pattern "desync|out.of.sync|mismatch|disconnect" |
				ForEach-Object { "${networkLogName}: $_" }
			$summary += $networkMatches
		}
	}
	$summary += ""
}
$summary | Set-Content -LiteralPath $summaryPath -Encoding UTF8

Write-Output "Evidence=$outputPath"
Write-Output "Manifest=$manifestPath"
Write-Output "Missing=$($missing.Count)"
Write-Output "ModFiles=$modComparison"
Write-Output "LOTMGameplayStream=$gameplayComparison"
if ($missing.Count -gt 0) {
	exit 2
}
