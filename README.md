# awesome-automations

n8n workflows and PowerShell scripts I actually use. Everything runs self-hosted and on free tiers where I could manage it.

This repo started when I moved 200+ scenarios from Make.com to self-hosted n8n. Some of what came out of that migration seemed worth sharing, so I'm cleaning things up and adding them here as I go.

## n8n workflows

Each folder has a workflow.json you can import (n8n > Workflows > Import from file) and a readme with setup steps.

[ai-bill-extractor](n8n/ai-bill-extractor/) watches Gmail for bill emails, pulls out the account number, due date, amount and the bill link with AI, then writes a row to Google Sheets. No parsing rules to maintain, the model reads the email like you would. Runs on the Gemini API free tier so it costs nothing.

[docs-chatbot](n8n/docs-chatbot/) is a chat widget for your website that answers from your own docs. Upload your FAQs through a form, embed one snippet, and visitors get answers grounded in your content. Supabase vector store, OpenRouter free models, Gemini free embeddings. Also fully free to run.

[call-to-hubspot-lead](n8n/call-to-hubspot-lead/) turns an inbound call into a HubSpot lead. Your phone system (3CX, Twilio, whatever can fire a webhook) sends the caller's number, it gets looked up in HubSpot, and either a new deal lands on the existing contact or a fresh contact + deal gets created. Repeat callers don't turn into duplicate contacts.

[gmail-ai-auto-labeler](n8n/gmail-ai-auto-labeler/) has AI sort your inbox into labels (invoices, banking, action required, newsletters, notifications, personal) instead of you maintaining filter rules that rot. Whatever the model can't place goes to an AI_UNSORTED label so mistakes stay visible. Gemini free tier, so also zero cost.

[agency-ops-automation-suite](n8n/agency-ops-automation-suite/) is one workflow that handles four agency chores at once: tagging new files by client, writing weekly client reports, drafting replies you approve before they send, and setting up a new client's folders and docs from a single sheet row. Google Drive, Sheets, Slack, Notion, Telegram, and Gemini, all on free tiers. Built with fake data as a portfolio piece.

## Powershell scripts

[make-blueprint-exporter](powershell/make-blueprint-exporter/) downloads every scenario blueprint in a Make.com team as json files. I wrote it for my own migration. Works fine as a plain backup tool too.

## License

MIT. Do what you want with it, credit is nice but not required.
