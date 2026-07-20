# Inbound call to HubSpot lead

When a call comes in, this creates the lead in HubSpot for you. Your phone system (3CX, or any PBX that can fire a webhook on a call) sends the caller's number, n8n looks it up in HubSpot, and either attaches a new deal to the existing contact or creates a fresh contact + deal. No more typing callers into the CRM by hand.

The dedupe matters: a repeat caller doesn't become a duplicate contact, they get a new deal on the record you already have.

## How it works

```
phone system --webhook--> n8n
                            |
                    search HubSpot by phone number
                            |
                 ┌──────────┴──────────┐
             found?                  not found?
         attach new deal        create contact,
         to the contact         then create deal
```

## The stack, all free

- n8n, self-hosted or cloud
- HubSpot free CRM + a free private-app token
- 3CX (or any phone system that can POST a webhook on a call event)

## Setup

### 1. HubSpot private app

In HubSpot: Settings > Integrations > Private Apps > Create a private app. Give it these scopes:

- `crm.objects.contacts.read`
- `crm.objects.contacts.write`
- `crm.objects.deals.read`
- `crm.objects.deals.write`

Copy the access token.

### 2. Import the workflow

n8n > Workflows > Import from file > workflow.json

### 3. Credential

On each of the three HTTP nodes (Search contact, Create contact, Create deal), pick a **HubSpot App Token** credential and paste your token. You make the credential once, then select it on the other two.

### 4. Point your phone system at it

Publish the workflow, open the **Incoming call** node, copy the production webhook URL. In 3CX: Admin > Settings > CRM / webhook integration, set it to fire on inbound call and POST a body like:

```json
{ "caller_number": "+15551234567", "caller_name": "Jane Doe" }
```

`caller_name` is optional. 3CX's variable for the caller number goes in `caller_number`. Other PBXs (FreePBX, Twilio, Aircall...) work the same way, just map their call-event fields to `caller_number`.

## Testing it (no phone system needed)

This is the part people worry about. You don't need 3CX to test, you just send the same JSON a call would.

1. Publish the workflow so the production webhook is live (or use the test URL while the editor is listening)
2. From PowerShell, fire a fake call:

```powershell
$body = Get-Content "sample-call.json" -Raw
Invoke-RestMethod -Uri "https://YOUR-N8N/webhook/inbound-call" -Method Post -Body $body -ContentType "application/json"
```

3. Check HubSpot: a new contact (Test Caller, +15557654321) and a deal ("Inbound call | +15557654321") should appear, linked together
4. Run the same command again. This time it should NOT create a second contact, it attaches another deal to the existing one. That proves the dedupe branch works

curl version if you prefer:

```bash
curl -X POST https://YOUR-N8N/webhook/inbound-call \
  -H "Content-Type: application/json" \
  -d '{"caller_number":"+15557654321","caller_name":"Test Caller"}'
```

## Customizing

- The deal is created with just a `dealname`. To drop it into a specific pipeline/stage, add `pipeline` and `dealstage` (their internal IDs) to the properties in both Create deal nodes. Don't add properties you haven't confirmed exist on your account first — HubSpot rejects the whole request if any property name doesn't exist (`PROPERTY_DOESNT_EXIST`), some fields like custom lead-source properties are only on paid tiers or need to be created manually under Settings > Properties first
- Want a Slack or Google Chat ping on every call too? Add a notification node after each Create deal
- `hs_lead_status: NEW` on the contact marks it as a fresh lead; remove it if you don't use lead status

## Notes

- `associationTypeId: 3` is HubSpot's built-in "deal to contact" link, that's what ties the deal to the caller
- Matching is by the `phone` property, so store numbers consistently (E.164 like +15551234567 is safest). If your CRM stores them differently, the search won't match and you'll get duplicates
- Free HubSpot has generous API limits, way more than call volume for most businesses

## License

[MIT](../../LICENSE)
