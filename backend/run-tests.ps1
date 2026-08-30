<#
.SYNOPSIS
    Runs the SUnit suite headless, in a throwaway copy of the image.

.DESCRIPTION
    Running tests inside the development image is convenient right up until a
    test wedges a socket: the UI process blocks, the IDE freezes, and killing it
    loses every unsaved change in the image. This script sidesteps that entirely
    by working on a copy in TEMP, the same way CI works on a fresh image.

    The development image is never opened, never written to, never at risk.

.EXAMPLE
    .\run-tests.ps1
    .\run-tests.ps1 -Integration
#>
[CmdletBinding()]
param(
    # Also run InventoryService-Tests-Integration, which starts a real HTTP
    # server. Excluded by default for the reason described above.
    [switch] $Integration,

    # Folder holding the image to copy. Point this at a pristine image created
    # in Pharo Launcher for a genuine clean-room run; the default is the
    # development image, which is fine for a quick check.
    [string] $ImageDir = (Join-Path $env:USERPROFILE 'Documents\Pharo\images\InventoryService')
)

$ErrorActionPreference = 'Stop'

$backend = Split-Path -Parent $MyInvocation.MyCommand.Path
$src     = Join-Path $backend 'src'

# --- locate the VM that Pharo Launcher installed -----------------------------
# Pharo Launcher keeps VMs under Documents\Pharo\vms on Windows; older or
# custom installs may put them under LOCALAPPDATA. Search both, newest wins.
$vmRoots = @(
    (Join-Path $env:USERPROFILE 'Documents\Pharo\vms'),
    (Join-Path $env:LOCALAPPDATA 'Pharo')
) | Where-Object { Test-Path $_ }

$vm = $vmRoots |
      ForEach-Object { Get-ChildItem $_ -Recurse -Filter 'PharoConsole.exe' -ErrorAction SilentlyContinue } |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1

if (-not $vm) {
    throw "PharoConsole.exe not found under $($vmRoots -join ' or '). Install a VM through Pharo Launcher first."
}
Write-Host "VM:    $($vm.FullName)"

# --- take a throwaway copy of the image --------------------------------------
if (-not (Test-Path $ImageDir)) { throw "Image folder not found: $ImageDir" }
$work = Join-Path $env:TEMP 'inventory-service-tests'

if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Path $work | Out-Null

foreach ($pattern in '*.image', '*.changes', '*.sources') {
    Get-ChildItem $ImageDir -Filter $pattern | Copy-Item -Destination $work
}

$image = (Get-ChildItem $work -Filter '*.image' | Select-Object -First 1).FullName
Write-Host "Image: $image`n"

# --- load the current source into the copy -----------------------------------
$group = if ($Integration) { 'all' } else { 'default' }

$load = @"
Metacello new
    baseline: 'InventoryService';
    repository: 'tonel://$src';
    onConflict: [ :ex | ex useIncoming ];
    onUpgrade: [ :ex | ex useIncoming ];
    load: '$group'
"@

Write-Host "Loading '$group' from $src ..."
& $vm.FullName $image eval --save $load
if ($LASTEXITCODE -ne 0) { throw "Metacello load failed (exit $LASTEXITCODE)" }

# --- run ---------------------------------------------------------------------
$packages = @('InventoryService-Tests')
if ($Integration) { $packages += 'InventoryService-Tests-Integration' }

$failed = $false
foreach ($package in $packages) {
    Write-Host "`n=== $package ==="
    & $vm.FullName $image test --junit-xml-output $package
    if ($LASTEXITCODE -ne 0) { $failed = $true }
}

if ($failed) {
    Write-Host "`nFAILED" -ForegroundColor Red
    exit 1
}
Write-Host "`nPASSED" -ForegroundColor Green
