# Gmail AI auto-labeler

AI reads every email that hits your inbox and files it under one of six labels. No filter rules, no "if sender contains" lists that break the moment a company changes its email domain. The model reads the mail like you would and decides where it goes.

Categories out of the box:

```
INVOICE          bills, receipts, payment requests, purchase orders
BANKING          statements, transaction alerts, OTP codes
ACTION_REQUIRED  a person is actually waiting on you
NEWSLETTER       marketing, digests, cold outreach
NOTIFICATION     automated mail that needs no reply
PERSONAL         friends and family
```

Anything the model can't place gets an `AI_UNSORTED` label instead of silently landing in the wrong bucket. That one label is doing a lot of work: when the classifier misfires you see it immediately, and the fix is usually one line in the prompt.

I ran Gmail filters for years before this. The problem with filters isn't setting them up, it's that they rot. New sender, new subject line format, and suddenly your invoices are sitting unread in the promotions tab. The AI version has no rules to rot.

Runs entirely on free tiers. The classification prompt is tiny (sender, subject, first 1500 chars of the body) so you won't get anywhere near the rate limits with a personal inbox.

## The stack

- n8n, self-hosted or cloud
- Gmail
- Google Gemini API on the free tier (Gemma model, no card needed)

## How it works

Gmail Trigger polls for unread mail every minute. Each email goes to Gemini with a prompt that says "reply with exactly one category name". A Switch node routes on the answer, seven branches, and each branch adds the matching Gmail label. That's the whole thing. Five node types.

## Setup

About 10 minutes if you already have a Google Cloud project, 20 if not.

### 1. Create the labels in Gmail

In Gmail, Settings > Labels > Create new label. Make all seven:

```
INVOICE, BANKING, ACTION_REQUIRED, NEWSLETTER, NOTIFICATION, PERSONAL, AI_UNSORTED
```

Do this first. The n8n label dropdowns can only pick labels that already exist.

### 2. Import the workflow

n8n > Workflows > Import from file > workflow.json

### 3. Google Cloud project

Skip to step 4 if you already have OAuth credentials from one of my other workflows, they work here too.

1. Go to console.cloud.google.com and create a project
2. APIs & Services > Library. Enable the Gmail API
3. OAuth consent screen > External. Add yourself as a test user
4. Clients > Create client > Web application. Under authorized redirect URIs paste the redirect URL n8n shows in the credential dialog (`https://YOUR-N8N/rest/oauth2-credential/callback`), then copy the client id and secret

### 4. Credentials in n8n

- Gmail Trigger node: new Gmail OAuth2 credential with the client id/secret, sign in with Google. Click through the "unverified app" warning, it's your own app
- Classify with AI node: free API key from aistudio.google.com, saved as a Google Gemini(PaLM) API credential
- The seven Label nodes take the same Gmail credential

### 5. Pick the labels

Open each Label node and pick its label from the dropdown (Label: INVOICE gets the INVOICE label and so on). This is the most tedious part of the setup and it's still only seven dropdowns.

### 6. Test it

Send yourself an email that looks like a bill, hit Execute Workflow, and watch it land under INVOICE. Then activate the workflow and let it run.

## Changing the categories

Two places, keep them in sync:

1. The prompt in the Classify with AI node (the category list with descriptions)
2. The Switch node rules (one branch per category)

Then add a Label node for the new branch. The descriptions in the prompt matter more than the names, that's what the model actually routes on. Vague descriptions get you vague sorting.

## Notes

- The trigger only looks at unread mail, so your archive won't get reprocessed on the first run
- If the model returns something weird, the fallback catches it. Check AI_UNSORTED once a week and tune the prompt descriptions if a pattern shows up
- Want it to also mark newsletters as read, or archive notifications? Add a Gmail node with the Mark as Read operation after the label node on that branch

Questions? Open an issue.
