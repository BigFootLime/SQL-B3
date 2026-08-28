$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
python scripts/prepare_data.py
if ($LASTEXITCODE -ne 0) { throw 'Préparation des données échouée.' }
docker compose up -d --wait
if ($LASTEXITCODE -ne 0) { throw 'Démarrage PostgreSQL échoué.' }
New-Item -ItemType Directory -Force rapports/logs | Out-Null
$scriptsSql = @('sql/01_lab01_environment.sql', 'sql/00_pagila.sql',
    'sql/02_lab02_ddl_dml.sql', 'sql/03_lab03_queries.sql', 'sql/04_lab04_queries.sql',
    'projet_final.sql', 'tests/projet.sql', 'tests/optimisation.sql', 'tests/benchmark.sql', 'sql/demo.sql')
foreach ($scriptSql in $scriptsSql) {
    $logSql = 'rapports/logs/' + [IO.Path]::GetFileNameWithoutExtension($scriptSql) + '.log'
    docker compose exec -T -w /workspace postgres psql -X -v ON_ERROR_STOP=1 -v repo_root=/workspace -U labuser -d blogapp_lab -f $scriptSql *> $logSql
    if ($LASTEXITCODE -ne 0) { Get-Content $logSql -Tail 30; throw "Échec de $scriptSql" }
    Write-Host "$scriptSql : OK"
}
