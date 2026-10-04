<#
.SYNOPSIS
    Helper for Windows PowerShell. Same commands as ./odoo.sh.

.EXAMPLE
    .\odoo.ps1 up
    .\odoo.ps1 install sale,crm
    .\odoo.ps1 help
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = 'Interactive helper: messages are for the person at the terminal, not pipeline output.')]
param(
    [Parameter(Position = 0)]
    [string] $Command = 'help',

    # Untyped on purpose: PowerShell turns `sale,crm` into an array, which is joined back below.
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [object[]] $Arguments = @()
)

$ErrorActionPreference = 'Stop'

$Usage = @'
Usage: .\odoo.ps1 <command> [arguments]

Stack:
  up                       Build and start Odoo and PostgreSQL
  down                     Stop and remove the containers (data is kept)
  restart                  Restart Odoo (after Python or config changes)
  logs [service]           Follow logs (default: odoo)
  status                   Show container status
  bash                     Open a shell inside the Odoo container
  tools                    Start pgAdmin on http://localhost:5050
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

$Rest = @($Arguments | Where-Object { $null -ne $_ } | ForEach-Object {
    if ($_ -is [array]) { $_ -join ',' } else { [string]$_ }
})

function Invoke-Compose {
    & docker compose @args
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Get-TtyArgument {
    # Allocate a TTY only when there is one (keeps CI and pipes working).
    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { return @('-T') }
    return @()
}

function Invoke-Helper {
    $flags = @(Get-TtyArgument)
    Invoke-Compose exec @flags odoo odoo-docker @args
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
        $line = Get-Content .env | Where-Object { $_ -match "^$Name=" } | Select-Object -Last 1
        if ($line) {
            $value = ($line -split '=', 2)[1].Trim()
            if ($value) { return $value }
        }
    }
    return $Default
}

function Initialize-Project {
    if (-not (Test-Path .env)) {
        Copy-Item .env.example .env
        Write-Host 'Created .env from .env.example. Review it any time.'
    }
    # Create bind-mount folders ourselves so Docker does not create them.
    foreach ($dir in 'addons\enterprise', 'addons\third_party', 'addons\custom', 'backups') {
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    }
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
        'status'  { Invoke-Compose ps }
        'bash' {
            $flags = @(Get-TtyArgument)
            Invoke-Compose exec @flags odoo bash
        }
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
