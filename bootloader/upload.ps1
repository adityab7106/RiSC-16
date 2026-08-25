<#
.SYNOPSIS
    Assemble a RiSC-16 program and upload it to the Basys-3 bootloader.

.DESCRIPTION
    One command does the whole flow: sets up the Python venv on first run,
    builds the assembler if needed, assembles program.s, and sends the result
    over the USB-UART link.

.EXAMPLE
    .\upload.ps1
    Assemble program.s and upload it.

.EXAMPLE
    .\upload.ps1 -Program test.s -Port COM4
    Assemble a different file and force a specific COM port.

.EXAMPLE
    .\upload.ps1 -ListPorts
    Show every serial port so you can find the board.
#>

[CmdletBinding()]
param(
    [string] $Program   = "program.s",
    [string] $Port      = "",
    [int]    $Baud      = 115200,
    [switch] $ListPorts,
    [switch] $Rebuild       # force the assembler to recompile
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$Venv       = Join-Path $PSScriptRoot ".venv"
$VenvPython = Join-Path $Venv "Scripts\python.exe"
$AsmExe     = Join-Path $PSScriptRoot "assembler.exe"
$AsmSrc     = Join-Path $PSScriptRoot "assembler\assembler.c"
$HexFile    = [System.IO.Path]::ChangeExtension($Program, ".hex")

function Fail($msg) {
    Write-Host ""
    Write-Host $msg -ForegroundColor Red
    exit 1
}

function Step($msg) {
    Write-Host "==> $msg" -ForegroundColor Cyan
}

# ---------------------------------------------------------------- Python venv
if (-not (Test-Path $VenvPython)) {
    Step "Creating Python virtual environment"

    $py = Get-Command py -ErrorAction SilentlyContinue
    if (-not $py) { $py = Get-Command python -ErrorAction SilentlyContinue }
    if (-not $py) {
        Fail "Python not found. Install it from https://www.python.org/downloads/ (tick 'Add to PATH')."
    }

    & $py.Source -m venv $Venv
    if ($LASTEXITCODE -ne 0) { Fail "Could not create the virtual environment." }

    Step "Installing pyserial"
    & $VenvPython -m pip install --quiet --upgrade pip
    & $VenvPython -m pip install --quiet -r requirements.txt
    if ($LASTEXITCODE -ne 0) { Fail "Could not install pyserial." }
}

# --------------------------------------------------------------- port listing
if ($ListPorts) {
    & $VenvPython host\uploader.py --list
    exit $LASTEXITCODE
}

# ------------------------------------------------------------------ assembler
$needsBuild = $Rebuild -or
              (-not (Test-Path $AsmExe)) -or
              ((Get-Item $AsmSrc).LastWriteTime -gt (Get-Item $AsmExe -ErrorAction SilentlyContinue).LastWriteTime)

if ($needsBuild) {
    Step "Building the assembler"

    $gcc = Get-Command gcc -ErrorAction SilentlyContinue
    $cl  = Get-Command cl  -ErrorAction SilentlyContinue

    if ($gcc) {
        & $gcc.Source -Wall -Wextra -O2 -o $AsmExe $AsmSrc
    }
    elseif ($cl) {
        & $cl.Source /nologo /O2 /Fe:$AsmExe $AsmSrc | Out-Null
    }
    else {
        Fail @"
No C compiler found.

Install one of:
  w64devkit  https://github.com/skeeto/w64devkit/releases   (unzip, no installer)
  MSYS2      https://www.msys2.org/
or open a Visual Studio Developer PowerShell so 'cl' is on the PATH.
"@
    }

    if ($LASTEXITCODE -ne 0) { Fail "The assembler failed to compile." }
}

# ------------------------------------------------------------------ assemble
if (-not (Test-Path $Program)) { Fail "$Program not found." }

Step "Assembling $Program"
& $AsmExe $Program $HexFile
if ($LASTEXITCODE -ne 0) { Fail "Assembly failed." }

# -------------------------------------------------------------------- upload
Step "Uploading $HexFile"

$uploadArgs = @("host\uploader.py", $HexFile, "--baud", $Baud)
if ($Port) { $uploadArgs += @("--port", $Port) }

& $VenvPython @uploadArgs
if ($LASTEXITCODE -ne 0) {
    Fail "Upload failed. If the port is busy, close Vivado's Hardware Manager and try again."
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green