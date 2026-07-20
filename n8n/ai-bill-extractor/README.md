# AI utility bill extractor

Gets bill emails out of your inbox and into a spreadsheet without you touching them. Gmail trigger, AI extraction, Google Sheets. The whole stack is free.

When a bill lands in Gmail, the workflow reads it, has the AI pull out the fields, and appends a row to your sheet:

Account_No, Billing_Period, Due_Date, Amount_Due, Bill_URL, Delivered_To

I built this because I was tracking utility bills across several mailboxes by hand. Regex parsers kept breaking every time a provider changed their email template. An LLM doesn't care about the template, it just reads the email. That's the whole trick.

Works for any provider (electricity, water, internet, phone) since there are no per-provider rules. You point the Gmail filter at the right sender or subject and that's it.

## the stack

- n8n, self-hosted or cloud
- Gmail
- Google Gemini API on the free tier (Gemma model, no card needed)
- Google Sheets

## setup

Takes maybe 15 minutes, most of it in Google Cloud Console.

### 1. import the workflow

n8n > Workflows > Import from file > workflow.json

### 2. Google Cloud project

One project covers both Gmail and Sheets.

1. Go to console.cloud.google.com and create a project
2. APIs & Services > Library. Enable Gmail API, Google Sheets API and Google Drive API (Drive is what n8n's spreadsheet picker uses, you get a 403 without it, ask me how I know)
3. OAuth consent screen > External. Add yourself as a test user
4. Clients > Create client > Web application. Under authorized redirect URIs paste the redirect URL n8n shows in the credential dialog, it looks like `https://YOUR-N8N/rest/oauth2-credential/callback`. Then copy the client id and secret

### 3. credentials in n8n

- Gmail Trigger node: new Gmail OAuth2 credential with the client id/secret, sign in with Google. You'll hit an "unverified app" warning since it's your own app, click through it
- Append to Sheet node: same client id/secret, new Google Sheets OAuth2 credential
- Extract with AI node: grab a free API key at aistudio.google.com and save it as a Google Gemini(PaLM) API credential

### 4. the spreadsheet

Make a Google Sheet with a tab called `Bills` and these headers in row 1:

```
Account_No | Billing_Period | Due_Date | Amount_Due | Bill_URL | Delivered_To
```

Pick it in the Append to Sheet node once the credential is attached.

### 5. point it at your bills

In the Gmail Trigger, set the search to match your provider:

```
from:billing@yourprovider.com
```

or a subject match if the sender varies.

### 6. test it

Send yourself the email from [sample-bill-email.txt](sample-bill-email.txt), set the filter to `subject:"Utility Bill Test"`, hit Execute Workflow. A row should show up in the sheet. Then set the filter back to the real provider and activate.

## model notes (mid 2026)

The workflow ships with `gemma-4-26b-a4b-it` because that's what actually has free quota on a new Gemini API key right now. The gemini-2.x models return quota 0 for new keys and 2.5 got retired for new users. Found that out the hard way.

Gemma also ignores the API's json output mode and wraps its answer in a json code fence. The Fields node already deals with this (it fishes the json out of the text), so nothing to fix, just don't be surprised when you look at the raw output.

The free tier throws an occasional "service unavailable, high demand" error. The AI node retries itself, 4 tries with 5s waits. Hasn't failed all four for me yet.

If you have a paid OpenAI or Anthropic key you can swap the AI node for one of those, the prompt works as is. gpt-4o-mini works out to about $0.0003 per bill if you're curious.

## adapting it

Same pattern works for anything that arrives by email and belongs in a table: invoices, receipts, order confirmations, bookings. Change the field list in the prompt, match it in the Fields node and the sheet headers. Done.

## license

[MIT](../../LICENSE)
