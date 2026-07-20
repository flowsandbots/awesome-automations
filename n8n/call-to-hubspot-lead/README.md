# Inbound call to HubSpot lead

When a call comes in, this creates the lead in HubSpot for you. Your phone system (3CX, Twilio, or any setup that can fire a webhook on a call) sends the caller's number, n8n looks it up in HubSpot, and either attaches a new deal to the existing contact or creates a fresh contact + deal. No more typing callers into the CRM by hand.

Removing duplicates is important: a repeat caller doesn't become a duplicate contact, they get a new deal on the record you already have.

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
- 3CX, Twilio, or any phone system that can POST a webhook on a call event

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

Publish the workflow, open the **Incoming call** node, copy the production webhook URL (`https://YOUR-N8N/webhook/inbound-call`). Every phone system below just needs to fire a POST to that URL with a body like:

```json
{ "caller_number": "+15551234567", "caller_name": "Jane Doe" }
```

`caller_name` is optional.

## The full flow, either way

```
caller dials your number
        |
3CX / Twilio fires a webhook on the call event
        |
n8n's "Incoming call" node receives it   <-- this workflow starts here
        |
n8n searches HubSpot for a contact with that phone number
        |
   found?  -----------------------------  not found?
   attach a new deal                     create the contact,
   to the existing contact               then create the deal
        |                                       |
        └───────────────  done  ────────────────┘
              caller now has a fresh deal
              waiting in your HubSpot pipeline
```

n8n doesn't touch the phone call itself, it just reacts to a webhook the phone system sends. So the "integration" work is entirely on the phone system's side: telling it to POST to your n8n URL when a call comes in.

### 3CX

3CX doesn't have a plain "webhook on every call" toggle in the basic settings, the webhook part usually needs one of two places:

- **Call Flow Designer (CFD):** if you're routing calls through a CFD flow (common for IVRs/queues), add a "Make HTTP Request" / script action at the start of the flow and point it at your n8n URL. The CFD gives you access to the caller ID variable, map that into `caller_number` in the request body.
- **3CX CRM Integration:** newer 3CX builds have a generic CRM/webhook integration under Admin > Integrations. If your version has it, that's the more direct route, point the "on call" event at your n8n URL the same way you'd point it at a real CRM.

Either way you're just telling 3CX "when a call comes in, POST this JSON to this URL" — the exact menu path shifts between 3CX versions, so if you don't see CFD or a webhook option, check your version's admin docs for "call flow" or "CRM integration."

### Twilio

Twilio is more straightforward since it's built to be scripted:

1. Buy or use an existing Twilio phone number (Console > Phone Numbers)
2. Under that number's configuration, find "A call comes in" — Twilio wants a **voice webhook URL** here, but Twilio's voice webhook expects TwiML back (instructions for how to handle the call itself), not just a fire-and-forget POST. Two ways to also notify n8n:
   - **Simplest:** point "A call comes in" straight at your n8n webhook URL. n8n needs to respond with valid TwiML (even just `<Response><Dial>your-forwarding-number</Dial></Response>`) so Twilio knows what to do with the call. Add a "Respond to Webhook" node after the HubSpot lookup that returns that TwiML.
   - **Cleaner:** keep Twilio's own call handling (TwiML Bin, Twilio Studio, or your existing Twilio app) exactly as it is, and add a **Status Callback** URL (also under the number's config, or per-call if you're using the API/Studio) pointed at your n8n webhook. Status callbacks fire on call events without you needing to return TwiML, so this doesn't interfere with however the call is already being routed.
3. Twilio sends its own field names (`From`, `CallSid`, etc.), not `caller_number` — add a small Set node right after the Incoming call node to map `{{ $json.body.From }}` into `caller_number` before it hits the HubSpot search.

### Other systems (FreePBX, Aircall, etc.)

Same idea: find wherever that system lets you fire a webhook or HTTP request on a call event, point it at your n8n URL, and map its caller-number field into `caller_number`. If the field names differ from `caller_number`/`caller_name`, add a Set node right after "Incoming call" to rename them before the rest of the workflow runs.

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
