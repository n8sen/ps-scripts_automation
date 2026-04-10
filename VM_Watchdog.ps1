<#

HyprV VM watchdog
Scans all VMs, asks which ones to manage, and keeps them running.

N8

███╗   ██╗███████╗
████╗  ██║██╔══██║
██╔██╗ ██║███████║  
██║╚██╗██║██╔══██║
██║ ╚████║███████║
╚═╝  ╚═══╝╚══════╝

#>

# How often to check VM state, in seconds
$CheckIntervalSeconds = 60

# Store selected VM names here
$ManagedVMs = @()

try {
    $allVMs = Get-VM | Sort-Object Name
}
catch {
    Write-Host "Failed to get VMs. Make sure Hyper-V PowerShell module is available and run this as Administrator." -ForegroundColor Red
    exit 1
}

if (-not $allVMs) {
    Write-Host "No VMs found on this Hyper-V host." -ForegroundColor Yellow
    exit 0
}

Write-Host "Detected VMs:`n" -ForegroundColor Cyan
$allVMs | ForEach-Object { Write-Host " - $($_.Name)" }

Write-Host "`nChoose which VMs should be kept running." -ForegroundColor Cyan

foreach ($vm in $allVMs) {
    do {
        $answer = Read-Host "Manage VM '$($vm.Name)'? (y/n)"
        $answer = $answer.Trim().ToLower()
    } while ($answer -notin @('y', 'n'))

    if ($answer -eq 'y') {
        $ManagedVMs += $vm.Name

        if ($vm.State -ne 'Running') {
            Write-Host "Starting '$($vm.Name)'..." -ForegroundColor Green
            try {
                Start-VM -Name $vm.Name -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Host "Failed to start '$($vm.Name)': $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "'$($vm.Name)' is already running." -ForegroundColor DarkGreen
        }
    }
}

if (-not $ManagedVMs) {
    Write-Host "`nNo VMs were selected. Exiting." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nNow monitoring selected VMs..." -ForegroundColor Cyan
Write-Host "Managed VMs: $($ManagedVMs -join ', ')" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop.`n" -ForegroundColor Yellow

while ($true) {
    foreach ($vmName in $ManagedVMs) {
        try {
            $vm = Get-VM -Name $vmName -ErrorAction Stop

            if ($vm.State -ne 'Running') {
                Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] '$vmName' is '$($vm.State)'. Starting it..." -ForegroundColor Yellow
                Start-VM -Name $vmName -ErrorAction Stop | Out-Null
            }
            else {
                Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] '$vmName' is running." -ForegroundColor DarkGray
            }
        }
        catch {
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Error with '$vmName': $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Start-Sleep -Seconds $CheckIntervalSeconds
}