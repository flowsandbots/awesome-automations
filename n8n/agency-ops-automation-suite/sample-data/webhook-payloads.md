# Test payloads for Section 3 (incoming message webhook)

Send these as POST requests to the webhook URL n8n gives you.
All fake, all safe to use.

## 1. Pricing question
```json
{
  "author": "curious_customer_88",
  "message": "Hey! Love your feed. How much do you charge for a monthly package?"
}
```

## 2. Complaint
```json
{
  "author": "annoyed_mike",
  "message": "Ordered two weeks ago and still nothing. This is really frustrating."
}
```

## 3. Compliment
```json
{
  "author": "happy_dana",
  "message": "Just wanted to say your content is the best in this space. Keep it up!"
}
```

## How to send one (from a terminal)
```
curl -X POST "PASTE_YOUR_WEBHOOK_URL_HERE" \
  -H "Content-Type: application/json" \
  -d '{"author":"curious_customer_88","message":"How much for a monthly package?"}'
```
