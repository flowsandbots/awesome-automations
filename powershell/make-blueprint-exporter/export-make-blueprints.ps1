# Export all Make.com (Integromat) scenario blueprints for a team.
#
# Useful for backups or migrating scenarios to another platform (e.g. n8n).
# Downloads every scenario blueprint as JSON plus a CSV inventory.
#
# Usage:
#   .\export-make-blueprints.ps1
#   (or: powershell -ExecutionPolicy Bypass -File .\export-make-blueprints.ps1)
#
# You will be prompted for:
#   - Zone:    the region in your Make URL (us1, us2, eu1, eu2, ...)
#   - Team ID: the number in your Make URL after the zone, e.g.
#              https://us1.make.com/123456/scenarios  ->  123456
#   - API token: create one in Make under Profile > API with scopes
#                scenarios:read and teams:read. Delete it when done.

$ErrorActionPreference = "Stop"

$Zone   = Read-Host "Make zone (e.g. us1, eu1)"
$TeamId = Read-Host "Team ID (number from your Make URL)"
$secure = Read-Host "Make API token" -AsSecureString
$Token  = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))

$BaseUrl = "https://$Zone.make.com/api/v2"
$Headers = @{ Authorization = "Token $Token" }

$OutDir = Join-Path $PSScriptRoot "make-blueprints"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# --- 1. List all scenarios (paginated) ---
$all = @()
$offset = 0
do {
    $resp = Invoke-RestMethod -Uri "$BaseUrl/scenarios?teamId=$TeamId&pg%5Blimit%5D=100&pg%5Boffset%5D=$offset" -Headers $Headers
    $batch = $resp.scenarios
    $all += $batch
    $offset += 100
} while ($batch.Count -eq 100)

Write-Host "Found $($all.Count) scenarios."

# --- 2. Save inventory ---
$all | Select-Object id, name, isActive, folderId, description |
    Export-Csv -Path (Join-Path $OutDir "_scenario-list.csv") -NoTypeInformation -Encoding UTF8

# --- 3. Download each blueprint ---
$i = 0
foreach ($s in $all) {
    $i++
    $safe = ($s.name -replace '[\\/:*?"<>|]', '_').Trim()
    if ($safe.Length -gt 80) { $safe = $safe.Substring(0, 80) }
    $file = Join-Path $OutDir ("{0}_{1}.json" -f $s.id, $safe)
    try {
        $bp = Invoke-RestMethod -Uri "$BaseUrl/scenarios/$($s.id)/blueprint" -Headers $Headers
        $bp.response.blueprint | ConvertTo-Json -Depth 100 | Set-Content -Path $file -Encoding UTF8
        Write-Host "[$i/$($all.Count)] OK  $($s.name)"
    } catch {
        Write-Host "[$i/$($all.Count)] FAILED  $($s.name)  ($($_.Exception.Message))" -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 300   # be gentle with rate limits
}

Write-Host ""
Write-Host "Done. Blueprints saved to: $OutDir"
Write-Host "Reminder: delete the API token in Make (Profile > API) if you no longer need it."
