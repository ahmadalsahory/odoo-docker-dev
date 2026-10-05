<#
.SYNOPSIS
    Helper for Windows PowerShell. Same commands as ./odoo.sh.

.EXAMPLE
    .\odoo.ps1 up
    .\odoo.ps1 install sale,crm
    .\odoo.ps1 help
#>
# No [Parameter()] attributes on purpose: they would turn this into an advanced script,
# and PowerShell would then grab flags such as `down -v` as its own (-Verbose).
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = 'Interactive helper: messages are for the person at the terminal, not pipeline output.')]
param()

$ErrorActionPreference = 'Stop'

# PowerShell turns `sale,crm` into an array; join it back into one argument.
$CliArgs = @($args | Where-Object { $null -ne $_ } | ForEach-Object {
    if ($_ -is [array]) { $_ -join ',' } else { [string]$_ }
})
$Command = if ($CliArgs.Count -gt 0) { $CliArgs[0] } else { 'help' }
$Rest = @($CliArgs | Select-Object -Skip 1)

$Usage = @'
Usage: .\odoo.ps1 <command> [arguments]

Stack:
  up                       Build and start Odoo and PostgreSQL
  down                     Stop and remove the containers (data is kept)
  restart                  Restart Odoo (after Python or config changes)
  logs [service]           Follow logs (default: odoo)
  status                   Show containers, Odoo version and addons path
  bash                     Open a shell inside the Odoo container
  tools                    Start pgAdmin (PGADMIN_PORT, default 5050)
  reset                    Delete the containers AND all data of this project

Odoo (DB defaults to ODOO_DB from .env):
  install <modules> [db]   Install comma-separated modules, then restart
  update <modules> [db]    Update comma-separated modules, then restart
  test <modules>           Run module tests in a fresh throwaway database
  shell [db]               Odoo Python shell
  psql [db]                PostgreSQL shell
  dbs                      List databases
  backup [db]              Save a backup zip into backups\
  restore <file> [db]      Restore a zip from backups\ as a new database
                           (add --neutralize for a copy of a production database)
  scaffold <name>          Create a new module in addons\custom
'@

function Exit-WithError([string] $Message) {
    Write-Host "Error: $Message" -ForegroundColor Red
    exit 1
}

function Invoke-Compose {
    # Compose writes progress to stderr. With 'Stop', Windows PowerShell 5.1 would turn
    # that into a terminating error in some hosts, so rely on the exit code instead.
    $ErrorActionPreference = 'Continue'
    & docker compose @args
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Test-OdooRunning {
    $ErrorActionPreference = 'Continue'
    $id = & docker compose ps --status running -q odoo 2> $null
    return [bool]$id
}

function Invoke-ComposeExec {
    if (-not (Test-OdooRunning)) { Exit-WithError 'Odoo is not running. Start it first: .\odoo.ps1 up' }
    # Allocate a TTY only when there is one (keeps CI and pipes working).
    $flags = @()
    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { $flags = @('-T') }
    Invoke-Compose exec @flags @args
}

function Invoke-Helper {
    Invoke-ComposeExec odoo odoo-docker-dev @args
}

function Invoke-OdooRestart {
    # Restart Odoo and return only once it answers again.
    Invoke-Compose restart odoo
    Invoke-Compose up -d --wait odoo
}

function Get-EnvValue([string] $Name, [string] $Default) {
    # Same precedence as Docker Compose: shell environment, then .env, then default.
    $fromShell = [Environment]::GetEnvironmentVariable($Name)
    if ($fromShell) { return $fromShell }
    if (Test-Path .env) {
        $line = Get-Content .env | Where-Object { $_ -match "^\s*$Name\s*=" } | Select-Object -Last 1
        if ($line) {
            # Strip a trailing " # comment" and surrounding quotes, like Compose does.
            $value = (($line -split '=', 2)[1] -replace '\s#.*$', '').Trim().Trim('"').Trim("'")
            if ($value) { return $value }
        }
    }
    return $Default
}

# Creates the default folders, and refuses custom paths that do not exist (Docker would
# silently create an empty folder and Odoo would start without those modules).
function Assert-AddonsPath([string] $Name, [string] $Default) {
    $path = Get-EnvValue $Name $Default
    if ($path -eq $Default) {
        if (-not (Test-Path $Default)) { New-Item -ItemType Directory -Path $Default | Out-Null }
    }
    elseif (-not (Test-Path -PathType Container $path)) {
        Exit-WithError "$Name=$path does not exist. Fix the path in .env."
    }
}

function Assert-DockerRunning {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Exit-WithError 'Docker is not installed. Install Docker Desktop: https://www.docker.com/products/docker-desktop/'
    }
    $ErrorActionPreference = 'Continue'
    & docker info *> $null
    if ($LASTEXITCODE -ne 0) {
        Exit-WithError ("Docker is not running. Start Docker Desktop, wait until it says it is running, then try again.`n" +
            'See docs/troubleshooting.md#docker-is-not-running')
    }
}

$PortDefaults = [ordered]@{ ODOO_PORT = '8069'; POSTGRES_PORT = '5433'; PGADMIN_PORT = '5050' }

# Returns the validated ports from .env, by setting name.
function Get-PortSetting {
    $ports = [ordered]@{}
    foreach ($name in $PortDefaults.Keys) {
        $value = Get-EnvValue $name $PortDefaults[$name]
        if ($value -notmatch '^\d{1,5}$' -or [int]$value -lt 1 -or [int]$value -gt 65535) {
            Exit-WithError "$name must be a port number between 1 and 65535, got '$value'."
        }
        $clash = $ports.Keys | Where-Object { $ports[$_] -eq [int]$value }
        if ($clash) { Exit-WithError "$clash and $name are both set to $value in .env. Give each one its own port." }
        $ports[$name] = [int]$value
    }
    return $ports
}

function Get-BindAddress {
    $address = Get-EnvValue 'BIND_ADDRESS' '127.0.0.1'
    $parsed = $null
    if (-not [Net.IPAddress]::TryParse($address, [ref]$parsed)) {
        Exit-WithError "BIND_ADDRESS must be an IP address such as 127.0.0.1 or 0.0.0.0, got '$address'."
    }
    return $address
}

# Returns $null when the port can be used, otherwise the socket error (e.g. AddressAlreadyInUse).
function Get-PortBindError([string] $Address, [int] $Port) {
    $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Parse($Address), $Port)
    try { $listener.Start(); return $null }
    catch {
        $e = $_.Exception
        while ($e.InnerException) { $e = $e.InnerException }
        return [string]$e.SocketErrorCode
    }
    finally { $listener.Stop() }
}

# Describes the program listening on a port, and the Windows service behind it if any.
function Get-PortOwner([int] $Port) {
    if (-not (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue)) { return $null }
    $connection = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $connection) { return $null }
    $procId = $connection.OwningProcess
    $owner = "$((Get-Process -Id $procId -ErrorAction SilentlyContinue).ProcessName) (process $procId)"
    # Services such as the Odoo Windows installer run Odoo as a child of a service wrapper.
    $ids = @($procId) + @((Get-CimInstance Win32_Process -Filter "ProcessId = $procId" -ErrorAction SilentlyContinue).ParentProcessId)
    $filter = ($ids | Where-Object { $_ } | ForEach-Object { "ProcessId = $_" }) -join ' OR '
    $services = @(Get-CimInstance Win32_Service -Filter $filter -ErrorAction SilentlyContinue | ForEach-Object Name)
    if ($services) { $owner += ", Windows service '$($services -join "', '")'" }
    return @{ Text = $owner; Services = $services; ProcessId = $procId }
}

# Fails with a clear message when another program holds the port. Docker's own error
# for this is cryptic and differs between systems.
function Assert-PortFree([string] $Name, [string] $Address, $Ports) {
    $port = $Ports[$Name]
    $ErrorActionPreference = 'Continue'
    # Containers of this project may hold the port already: Compose reuses or replaces them.
    $own = @(& docker compose ps -q 2> $null)
    $publishers = @(& docker ps --no-trunc --filter "publish=$port" --format '{{.ID}} {{.Names}}' 2> $null)
    if ($publishers | Where-Object { $own -contains ($_ -split ' ')[0] }) { return }
    $containers = @($publishers | ForEach-Object { ($_ -split ' ')[1] })

    $stop = $null
    if ($containers) {
        $problem = "is used by the Docker container $($containers -join ', ')"
        $stop = "Stop it: docker stop $($containers -join ' ')"
    }
    else {
        $bindError = Get-PortBindError $Address $port
        if ($null -eq $bindError) { return }
        if ($bindError -eq 'AddressNotAvailable') {
            Exit-WithError "BIND_ADDRESS=$Address is not an address of this computer. Use 127.0.0.1, or 0.0.0.0 for every network."
        }
        $owner = Get-PortOwner $port
        if ($owner -and $owner.Services) {
            $problem = "is used by $($owner.Text)"
            $stop = "Stop the service, as administrator: Stop-Service '$($owner.Services[0])'. " +
                'Set it to Manual in services.msc so it does not start with Windows again.'
        }
        elseif ($owner -and $owner.ProcessId -eq 4) {
            # The System process: a Windows component such as http.sys (IIS, WinRM...).
            $problem = 'is used by Windows itself (System process)'
        }
        elseif ($owner) {
            $problem = "is used by $($owner.Text)"
            $stop = 'Close that program.'
        }
        elseif ($bindError -eq 'AccessDenied') {
            # No program holds it: it is in a range Windows keeps for itself (Hyper-V, WSL...).
            $problem = 'is reserved by Windows (list: netsh int ipv4 show excludedportrange protocol=tcp)'
        }
        else {
            $problem = "cannot be used ($bindError)"
        }
    }

    # Windows reserves ports in blocks of 100, so look a bit further than that.
    $suggestion = ($port + 1)..([Math]::Min($port + 200, 65535)) | Where-Object {
        $Ports.Values -notcontains $_ -and $null -eq (Get-PortBindError $Address $_)
    } | Select-Object -First 1
    $other = if ($suggestion) { "set $Name=$suggestion in .env (free right now)" } else { "set another $Name in .env" }
    $options = @("Use another port: $other, then run the command again.")
    if ($stop) { $options = @($stop) + $options }
    Exit-WithError ("Port $port ($Name) $problem.`n" +
        (($options | ForEach-Object { "  - $_" }) -join "`n") + "`n" +
        'Details: docs/troubleshooting.md#port-already-in-use')
}

# Returns "<hash> <unix time>" of the Enterprise checkout, so the image installs the
# matching Community build (see docker/match-community.sh). Empty when there is no
# Enterprise Git clone.
function Get-EnterpriseCommit {
    $path = Get-EnvValue 'ENTERPRISE_ADDONS_PATH' './addons/enterprise'
    if (-not (Test-Path (Join-Path $path '.git'))) { return '' }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host 'Warning: Git is not installed, so Odoo cannot be matched to your Enterprise version.' -ForegroundColor Yellow
        return ''
    }
    $ErrorActionPreference = 'Continue'
    # safe.directory: folders on other drives often trip Git's ownership check.
    $result = & git -c 'safe.directory=*' -C $path log -1 --format='%H %ct' 2> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Warning: cannot read the Enterprise commit in $path, so Odoo cannot be matched to it." -ForegroundColor Yellow
        return ''
    }
    return "$result".Trim()
}

function Initialize-Project {
    if (-not (Test-Path .env)) {
        Copy-Item .env.example .env
        Write-Host 'Created .env from .env.example. Review it any time.'
    }

    $version = Get-EnvValue 'ODOO_VERSION' '20'
    if ($version -notmatch '^\d+$') {
        Exit-WithError "ODOO_VERSION must be a major version such as 20 (no .0), got '$version'."
    }

    Assert-AddonsPath 'ENTERPRISE_ADDONS_PATH' './addons/enterprise'
    Assert-AddonsPath 'THIRD_PARTY_ADDONS_PATH' './addons/third_party'
    Assert-AddonsPath 'CUSTOM_ADDONS_PATH' './addons/custom'
    if (-not (Test-Path backups)) { New-Item -ItemType Directory -Path backups | Out-Null }
}

Push-Location -LiteralPath $PSScriptRoot
try {
    if ($Command -notin 'help', '-h', '--help') { Assert-DockerRunning }
    switch ($Command) {
        'up' {
            Initialize-Project
            $ports = Get-PortSetting
            Assert-PortFree 'ODOO_PORT' (Get-BindAddress) $ports
            Assert-PortFree 'POSTGRES_PORT' '127.0.0.1' $ports
            $commit = @((Get-EnterpriseCommit) -split ' ') + @('', '')
            $env:ENTERPRISE_COMMIT = $commit[0]
            $env:ENTERPRISE_COMMIT_TIME = $commit[1]
            Write-Host 'Starting... the first run downloads images and can take a few minutes.'
            Invoke-Compose up -d --build --wait @Rest
            Write-Host "Odoo is ready at http://localhost:$(Get-EnvValue 'ODOO_PORT' '8069')"
        }
        'down'    { Invoke-Compose down @Rest }
        'restart' { Invoke-OdooRestart }
        'logs' {
            $service = if ($Rest.Count -gt 0) { $Rest[0] } else { 'odoo' }
            Invoke-Compose logs -f --tail 200 $service
        }
        'status' {
            Invoke-Compose ps
            if (Test-OdooRunning) { Invoke-Helper info }
        }
        'bash'    { Invoke-ComposeExec odoo bash }
        'tools' {
            Assert-PortFree 'PGADMIN_PORT' '127.0.0.1' (Get-PortSetting)
            Invoke-Compose --profile tools up -d pgadmin
            Write-Host "pgAdmin is at http://localhost:$(Get-EnvValue 'PGADMIN_PORT' '5050')"
        }
        'reset' {
            $answer = Read-Host "Delete all containers, databases and filestore of this project? Type 'yes'"
            if ($answer -ne 'yes') { Write-Host 'Cancelled.'; exit 1 }
            Invoke-Compose --profile tools down -v
        }
        { $_ -in 'install', 'update' } {
            Invoke-Helper $Command @Rest
            Invoke-OdooRestart
        }
        'scaffold' {
            Invoke-Helper $Command @Rest
            # Restart so the server rescans addons\custom (it may have been empty until now).
            Invoke-OdooRestart
        }
        { $_ -in 'test', 'shell', 'psql', 'dbs', 'backup', 'restore' } {
            Invoke-Helper $Command @Rest
        }
        { $_ -in 'help', '-h', '--help' } { Write-Host $Usage }
        default {
            Write-Host $Usage
            exit 1
        }
    }
}
finally {
    Pop-Location
}
