# 🤖 Automations

Open-source automation templates and scripts. Everything here is self-hostable and built to run on free tiers wherever possible.

## 📂 Structure

```
automations/
├── n8n/          # importable n8n workflow templates
└── powershell/   # standalone PowerShell scripts
```

## ⚡ n8n workflows

| Workflow | What it does |
|---|---|
| [ai-bill-extractor](n8n/ai-bill-extractor/) | Gmail → free AI extraction (Gemma) → Google Sheets. Turns bill/invoice emails into spreadsheet rows automatically. |

**How to use:** each folder contains a `workflow.json` — import it via n8n → Workflows → *Import from File*, then follow the folder's README for credentials and setup.

## 🔧 PowerShell scripts

| Script | What it does |
|---|---|
| [make-blueprint-exporter](powershell/make-blueprint-exporter/) | Bulk-export every Make.com scenario blueprint as JSON — for backups or migrating to n8n. |

## License

[MIT](LICENSE) — use freely, attribution appreciated.
