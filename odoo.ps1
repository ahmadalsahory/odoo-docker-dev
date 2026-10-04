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
    Invoke-ComposeExec odoo odoo-docker @args
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
    switch ($Command) {
        'up' {
            Initialize-Project
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
