# Make.com blueprint exporter

PowerShell script that downloads every scenario blueprint in a Make.com team as json files, plus a csv listing all your scenarios.

I wrote this to migrate 200+ scenarios from Make to n8n. Exporting them one by one through the UI would have taken all day, this does the lot in a few minutes. It's also just a decent backup tool, Make has no bulk export of its own.

## What it does

1. Lists every scenario in your team (handles pagination)
2. Writes _scenario-list.csv with id, name, active status and folder for each one
3. Downloads each blueprint to make-blueprints/id_name.json

## Usage

First make an API token in Make: click your avatar > Profile > API tab > Add token, with the scopes `scenarios:read` and `teams:read`. That's read-only, it can't touch anything.

Then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\export-make-blueprints.ps1
```

It asks for three things:

- zone, the region in your Make URL (us1, us2, eu1, eu2...)
- team id, the number in the URL. https://us1.make.com/123456/scenarios means 123456
- the API token (input is hidden when you paste it)

Delete the token in Make when you're done with it.

## Worth knowing

Blueprints contain your scenario logic but not your credentials or connections, those never leave Make. They can still hold private stuff though (email addresses, sheet ids, internal hostnames), so treat the export folder as sensitive.

The script sleeps 300ms between requests to stay under Make's rate limits. 200 scenarios takes about 2 minutes.

## License

[MIT](../../LICENSE)
