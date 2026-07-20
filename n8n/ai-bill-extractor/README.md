# 📧 AI Utility Bill Extractor for n8n

Turn bill emails into spreadsheet rows automatically — **Gmail → free AI extraction → Google Sheets**, on a 100% free stack.

Every time a utility/service bill lands in your inbox, this workflow reads it, extracts the key fields with AI (no regex, no per-provider parsing rules), and appends a row to a Google Sheet:

| Account_No | Billing_Period | Due_Date | Amount_Due | Bill_URL | Delivered_To |
|---|---|---|---|---|---|
| 1023456789 | July-2026 | 04/08/2026 | USD 486.50 | https://… | you@gmail.com |

Works with any provider — electricity, water, internet, phone — because the AI finds the fields regardless of the email's layout. Just point the Gmail filter at your provider's emails.

## Why this instead of regex parsers?

Traditional email parsing breaks every time a provider redesigns their template. An LLM reads the email like a human does. This template uses Google's **Gemma** model via the Gemini API free tier — no credit card, $0.

## Stack

- [n8n](https://n8n.io) (self-hosted or cloud)
- Gmail (free)
- Google Gemini API — Gemma model, free tier, no card required
- Google Sheets (free)

## Setup (~15 min)

### 1. Import the workflow
n8n → Workflows → **Import from File** → `workflow.json`

### 2. Google Cloud project (one-time, powers Gmail + Sheets)
1. [console.cloud.google.com](https://console.cloud.google.com) → New project
2. **APIs & Services → Library** → enable **Gmail API**, **Google Sheets API**, and **Google Drive API** (Drive is needed for n8n's spreadsheet picker)
3. **OAuth consent screen** → External → add yourself as a **test user**
4. **Clients → Create client** → type **Web application** → under *Authorized redirect URIs*, paste the OAuth Redirect URL shown in n8n's credential dialog (`https://YOUR-N8N/rest/oauth2-credential/callback`) → copy the Client ID + Secret

### 3. Credentials in n8n
- **Gmail Trigger** node → create a *Gmail OAuth2* credential → paste Client ID/Secret → Sign in with Google (click through the "unverified app" warning — it's your own app)
- **Append to Sheet** node → create a *Google Sheets OAuth2* credential → same Client ID/Secret → sign in
- **Extract with AI** node → get a free API key at [aistudio.google.com](https://aistudio.google.com) → create a *Google Gemini(PaLM) API* credential

### 4. The spreadsheet
Create a Google Sheet with a tab named `Bills` and these headers in row 1:

```
Account_No | Billing_Period | Due_Date | Amount_Due | Bill_URL | Delivered_To
```

Select it in the **Append to Sheet** node.

### 5. Point it at your bills
In the **Gmail Trigger** node, set the search filter to match your provider, e.g.:

```
from:billing@yourprovider.com             # specific sender
subject:"Utility Bill"                      # or by subject
```

### 6. Test
Send yourself the sample email from [`sample-bill-email.txt`](sample-bill-email.txt), set the filter to `subject:"Utility Bill Test"`, and click **Execute Workflow**. A row should appear in your sheet. Then set the filter back to your real provider and **activate** the workflow.

## Model notes (as of mid-2026)

- The workflow ships with `gemma-4-26b-a4b-it` — the model with a real free tier on new Gemini API keys. Older `gemini-2.x` models return `quota: 0` on new keys, and `gemini-2.5` is retired for new users.
- Gemma ignores the API's JSON mode and wraps its answer in a ```json fence — the **Fields** node handles this by extracting and parsing the fenced JSON, so no changes needed.
- If you have a paid OpenAI/Anthropic key, you can swap the AI node for an OpenAI/Anthropic node; the prompt works as-is (cost ≈ $0.0003/bill on gpt-4o-mini).
- Occasional "Service unavailable / high demand" errors on the free tier are normal; the AI node retries automatically (4 tries, 5 s apart).

## Adapting to other documents

The pattern generalizes to any "email → structured data" task: invoices, receipts, order confirmations, booking confirmations. Edit the field list in the **Extract with AI** prompt and the **Fields** node, and match the columns in your sheet.

## License

[MIT](LICENSE)
