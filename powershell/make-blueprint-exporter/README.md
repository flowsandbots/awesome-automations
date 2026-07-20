# Make.com Blueprint Exporter

PowerShell script that downloads **every scenario blueprint** in a Make.com (formerly Integromat) team as JSON files, plus a CSV inventory.

Use it to back up your automations, or as step 1 of migrating from Make to another platform like n8n.

## What it does

1. Lists all scenarios in your team (handles pagination)
2. Saves `_scenario-list.csv` — id, name, active status, folder for every scenario
3. Downloads each scenario's blueprint to `make-blueprints/<id>_<name>.json`

## Usage

1. Create an API token in Make: click your avatar → **Profile** → **API** tab → **Add token** with scopes `scenarios:read` and `teams:read`
2. Run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\export-make-blueprints.ps1
   ```
3. Answer the prompts:
   - **Zone** — the region in your Make URL (`us1`, `us2`, `eu1`, `eu2`…)
   - **Team ID** — the number in your Make URL: `https://us1.make.com/123456/scenarios` → `123456`
   - **API token** — pasted input is hidden
4. Delete the token in Make when you're done

## Notes

- Read-only: the token scopes can't modify anything in your account
- Blueprints contain your scenario logic but **not** your credentials/connections
- Rate-limited to ~3 requests/second to stay well within Make's API limits
- Blueprints may contain private data (emails, sheet IDs, hostnames) — treat the export folder as sensitive
