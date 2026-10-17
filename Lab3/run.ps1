# Lab 3 (variant 5: I2C, VHDL) - one-click runner for Windows PowerShell 5.1
#
#   .\run.ps1            simulation (GHDL) + waveform PNGs (sim\fig_*.png)
#   .\run.ps1 -Wave      same + open tb_i2c.vcd in GTKWave (if installed)
#   .\run.ps1 -Syn       same + synthesis/timing (needs yosys + nextpnr in PATH)
#
# If PowerShell refuses to run scripts:
#   powershell -ExecutionPolicy Bypass -File .\run.ps1
param([switch]$Wave, [switch]$Syn)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$sim  = Join-Path $root 'sim'

# ---------- 1. GHDL: use the one in PATH, otherwise a portable copy in tools\ghdl
$ghdl = (Get-Command ghdl -ErrorAction SilentlyContinue).Source
if (-not $ghdl) {
    $ghdl = Join-Path $root 'tools\ghdl\bin\ghdl.exe'
    if (-not (Test-Path $ghdl)) {
        Write-Host '>> GHDL not found, downloading portable GHDL 5.1.1 (~23 MB)...' -ForegroundColor Yellow
        $zip = Join-Path $root 'tools\ghdl.zip'
        New-Item -ItemType Directory -Force (Join-Path $root 'tools') | Out-Null
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest 'https://github.com/ghdl/ghdl/releases/download/v5.1.1/ghdl-mcode-5.1.1-mingw64.zip' -OutFile $zip -UseBasicParsing
        Expand-Archive $zip -DestinationPath (Join-Path $root 'tools\ghdl') -Force
        Remove-Item $zip
    }
}
Write-Host ">> GHDL: $ghdl" -ForegroundColor Cyan

# ---------- 2. Compile, elaborate, run the testbench
Push-Location $sim
try {
    $ErrorActionPreference = 'Continue'   # GHDL prints reports to stderr
    Remove-Item work-obj08.cf -ErrorAction SilentlyContinue   # stale library -> clean rebuild
    & $ghdl -a --std=08 ..\src\i2c_master.vhd ..\src\i2c_slave.vhd ..\tb\tb_i2c.vhd
    if ($LASTEXITCODE -ne 0) { throw 'GHDL analysis failed' }
    & $ghdl -e --std=08 tb_i2c
    if ($LASTEXITCODE -ne 0) { throw 'GHDL elaboration failed' }
    $log = & $ghdl -r --std=08 tb_i2c --vcd=tb_i2c.vcd 2>&1 | ForEach-Object { "$_" }
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $log | Set-Content -Encoding utf8 sim_log.txt
    $log | ForEach-Object { Write-Host $_ }
    if ($code -ne 0 -or -not ($log -match 'ALL TESTS PASSED')) { throw 'Simulation FAILED - see sim\sim_log.txt' }
    Write-Host '>> Simulation OK, log: sim\sim_log.txt, waves: sim\tb_i2c.vcd' -ForegroundColor Green

    # ---------- 3. Waveform screenshots (matplotlib)
    $py = (Get-Command py -ErrorAction SilentlyContinue).Source
    if (-not $py) { $py = (Get-Command python -ErrorAction SilentlyContinue).Source }
    if ($py) {
        & $py -c 'import matplotlib' 2>$null
        if ($LASTEXITCODE -ne 0) { & $py -m pip install --quiet matplotlib }
        & $py plot_wave.py tb_i2c.vcd
        Write-Host '>> PNG waveforms: sim\fig_*.png' -ForegroundColor Green
    } else {
        Write-Host '>> Python not found - skipping PNG waveforms' -ForegroundColor Yellow
    }

    # ---------- 4. GTKWave (optional)
    if ($Wave) {
        $gtk = (Get-Command gtkwave -ErrorAction SilentlyContinue).Source
        if ($gtk) { Start-Process $gtk 'tb_i2c.vcd' }
        else { Write-Host '>> gtkwave not in PATH (https://sourceforge.net/projects/gtkwave/files/)' -ForegroundColor Yellow }
    }
} finally { Pop-Location }

# ---------- 5. Synthesis + timing (optional)
if ($Syn) {
    $yosys = Get-Command yosys -ErrorAction SilentlyContinue
    $pnr   = Get-Command nextpnr-ice40 -ErrorAction SilentlyContinue
    if (-not ($yosys -and $pnr)) {
        Write-Host '>> yosys/nextpnr not in PATH. Install OSS CAD Suite:' -ForegroundColor Yellow
        Write-Host '   https://github.com/YosysHQ/oss-cad-suite-build/releases  (then run its environment.ps1)'
        Write-Host '   Ready reports are already in syn\*_stat.txt and syn\*_pnr.log'
        return
    }
    Push-Location (Join-Path $root 'syn')
    try {
        foreach ($M in 'i2c_master', 'i2c_slave') {
            & yosys -m ghdl -p "ghdl --std=08 ../src/$M.vhd -e $M; synth_ice40 -top $M -json $M.json; tee -o ${M}_ice40_stat.txt stat"
            & nextpnr-ice40 --hx8k --package ct256 --json "$M.json" --pcf-allow-unconstrained --freq 50 --asc "$M.asc" -l "${M}_pnr.log"
            & yosys -m ghdl -p "ghdl --std=08 ../src/$M.vhd -e $M; synth_xilinx -family xc7 -top $M; tee -o ${M}_xc7_stat.txt stat"
        }
        Select-String -Path *_pnr.log -Pattern 'Max frequency' | ForEach-Object { Write-Host $_ }
    } finally { Pop-Location }
}
