# awesome-automations

n8n workflows and PowerShell scripts I actually use. Everything runs self-hosted and on free tiers where I could manage it.

This repo started when I moved 200+ scenarios from Make.com to self-hosted n8n. Some of what came out of that migration seemed worth sharing, so I'm cleaning things up and adding them here as I go.

## n8n workflows

Each folder has a workflow.json you can import (n8n > Workflows > Import from file) and a readme with setup steps.

[ai-bill-extractor](n8n/ai-bill-extractor/) watches Gmail for bill emails, pulls out the account number, due date, amount and the bill link with AI, then writes a row to Google Sheets. No parsing rules to maintain, the model reads the email like you would. Runs on the Gemini API free tier so it costs nothing.

[docs-chatbot](n8n/docs-chatbot/) is a chat widget for your website that answers from your own docs. Upload your FAQs through a form, embed one snippet, and visitors get answers grounded in your content. Supabase vector store, OpenRouter free models, Gemini free embeddings. Also fully free to run.

[call-to-hubspot-lead](n8n/call-to-hubspot-lead/) turns an inbound call into a HubSpot lead. Your phone system (3CX, Twilio, whatever can fire a webhook) sends the caller's number, it gets looked up in HubSpot, and either a new deal lands on the existing contact or a fresh contact + deal gets created. Repeat callers don't turn into duplicate contacts.

## Powershell scripts

[make-blueprint-exporter](powershell/make-blueprint-exporter/) downloads every scenario blueprint in a Make.com team as json files. I wrote it for my own migration. Works fine as a plain backup tool too.

## License

MIT. Do what you want with it, credit is nice but not required.
