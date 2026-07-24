# Agency ops automation suite

If you run a small social media agency, a lot of your week disappears into the same handful of chores: filing client files so you can find them later, writing up "here's how last week went" reports, replying to comments and DMs, and setting up each new client from scratch. This is one n8n workflow that takes all four off your plate. It sorts new files by client automatically, writes your weekly client reports for you, drafts replies to incoming messages and waits for your thumbs-up before anything goes out, and spins up a new client's folders and docs the moment you add them to a sheet. It runs on free tiers end to end, so it costs nothing to keep on.

Everything here is built with fake data as a portfolio project. There's no real client in it. See the note at the bottom for what that means and what you'd change to use it for real.

> Screenshots get added as each section is built and tested, so some images below may be missing until that section is done.

![The whole workflow on one canvas](screenshots/full-canvas.png)

It's one workflow with four independent parts. Each part has its own trigger, so they run on their own and don't interfere with each other. Here's what each one does.

## Section 1 — content auto-categorizer

This one runs whenever a new file lands in a Google Drive folder you pick. The AI reads the file name and works out three things: which client it's for, what kind of content it is (reel, carousel, blog, ad, and so on), and the file format. It writes those tags as a new row in a Google Sheet.

The result is a running log of every asset, tagged and searchable, without anyone renaming files by hand. If a file name is too vague to place confidently, it gets filed as "Unsorted" rather than a bad guess, so you can eyeball those later.

![A file getting tagged in the sheet](screenshots/section1-result.png)

## Section 2 — weekly client report

This one runs on a schedule. It's set to every Monday at 9am, but you can change that. It reads a sheet of the week's numbers, then the AI writes a short summary in plain English. It's not a data dump. It reads the numbers and tells the story of the week, and the tone follows the results: good week reads upbeat, a dip reads calm and honest, a flat week reads matter-of-fact. Then it posts that summary to Slack, and optionally saves a copy to Drive.

So every Monday morning there's a client-ready update sitting in your Slack channel that you didn't have to write.

![A report posted in Slack](screenshots/section2-result.png)

## Section 3 — draft a reply, you approve

This one runs when a comment or DM comes in. In this build the message arrives through a webhook, which stands in for whatever platform you actually use (more on that in the note at the bottom). The AI drafts a reply that fits the message: helpful for a pricing question, calm and apologetic for a complaint, gracious for a compliment. Then it sends the draft to you on Telegram with two buttons, Approve & send or Reject, and the workflow stops and waits.

So you get replies drafted for you, but you stay in control. If you tap Approve, it goes out. If you tap Reject, it's dropped. This part is worth saying plainly: there is no path in this workflow that sends a message without you pressing the button first.

![The approve/reject prompt in Telegram](screenshots/section3-approval.png)

## Section 4 — new client onboarding

This one runs when you add a new row to your "New Clients" sheet. Three things then happen on their own: a Drive folder is created for the client, a page is created in your Notion clients database, and a message is posted to your team's Slack channel.

So one row in gets you a fully set-up client out, instead of clicking through Drive and Notion to build the same starter setup every time. Because it only reacts to new rows, re-running it won't create duplicates of clients you've already set up.

![A new client set up across Drive, Notion and Slack](screenshots/section4-result.png)

## Setup

No prior n8n experience needed. Work through it top to bottom. It takes roughly an hour the first time, most of which is creating the credentials, and you only create those once.

### 1. Import the workflow

In n8n, go to Workflows, then the three-dot menu, then Import from File. Pick `agency-ops-automation-suite.json` from this folder. You'll see the four sections laid out on the canvas with a yellow note above each one explaining it.

![Importing the workflow file](screenshots/setup-import.png)

### 2. Create the credentials

The workflow talks to four services. You need a login (credential) for each. You make these once and every node reuses them.

Google covers both Drive and Sheets from the same Google Cloud project. In [console.cloud.google.com](https://console.cloud.google.com) create a project, then under APIs & Services enable the Google Drive API and Google Sheets API. On the OAuth consent screen, choose External and add yourself as a test user. Then create a Web application client, and paste the redirect URL n8n shows you (it looks like `https://YOUR-N8N/rest/oauth2-credential/callback`) into the allowed redirect URIs. Copy the client ID and secret into new Google credentials in n8n and sign in. You'll get an "unverified app" warning because it's your own project, so just click through it.

![Where to create Google credentials](screenshots/setup-google-cred.png)

For Slack, create a Slack app at [api.slack.com/apps](https://api.slack.com/apps), give it permission to post messages, install it to your workspace, and copy the bot token into a new Slack credential in n8n.

![Where to create the Slack credential](screenshots/setup-slack-cred.png)

For Notion, go to [notion.so/my-integrations](https://www.notion.so/my-integrations), create an integration, and copy its secret into a new Notion credential in n8n. Then share your clients database with that integration: in Notion, open the database, hit Share, and invite the integration by name. That last step trips people up. If Notion nodes can't see your database later, this is almost always why.

![Where to create the Notion credential](screenshots/setup-notion-cred.png)

Gemini is the AI behind the tagging, the report writing, and the reply drafting. Go to [aistudio.google.com](https://aistudio.google.com), create a free API key (no card needed), and paste it into a new Google Gemini (PaLM) API credential in n8n.

![Where to get the Gemini key](screenshots/setup-gemini-cred.png)

Telegram is what powers the approval buttons. Message [@BotFather](https://t.me/botfather) on Telegram, send `/newbot`, follow the prompts, and copy the bot token into a new Telegram credential in n8n. Then send your bot any message and grab your chat ID. The easiest way is to open `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates` in a browser after messaging it, and read the chat id from the response. You'll paste that chat ID into the approval node in the next step.

![Where to create the Telegram bot](screenshots/setup-telegram-cred.png)

### 3. Fill in your own details

A handful of nodes need you to point them at your stuff. Open each one and pick from the dropdown (they populate once the credential is attached). Here's the full list so nothing gets missed:

- **New file in Drive** (Section 1): choose the folder you want watched for new assets.
- **Log to tracking sheet** (Section 1): choose your tracking sheet. Its first row needs these headers: `file_name`, `client`, `content_type`, `format`, `tagged_at`.
- **Read performance data** (Section 2): choose your performance sheet.
- **Post report to Slack** (Section 2): choose the channel for reports.
- **Save copy to Drive** (Section 2): choose a folder, or delete this node if you don't want a saved copy.
- **Approve on Telegram** (Section 3): paste your Telegram chat ID.
- **New client row** (Section 4): choose your "New Clients" sheet.
- **Create Drive folder** (Section 4): choose the parent folder your client folders live under.
- **Create Notion page** (Section 4): choose your clients database.
- **Tell the team** (Section 4): choose the channel for onboarding announcements.

There are ready-made sample sheets and files in the `sample-data` folder next to this README, so you can set the whole thing up with fake data before pointing it at anything real.

![Picking a folder in a node](screenshots/setup-fill-in.png)

### 4. Test each section

Test them one at a time. Here's how to fire each and what a good result looks like.

**Section 1.** Drop a file into the watched folder named like `NorthwindCoffee_Reel_LatteArt.mp4`. Within a minute a new row appears in your tracking sheet tagged Northwind Coffee / Reel / MP4. Then drop `final_v2_FINAL_edited.png`, which should come back as Unsorted. That's the point of that one.

![Section 1 test result](screenshots/section1-test.png)

**Section 2.** You don't have to wait until Monday. Open the workflow and hit Execute to run it on the spot. With the sample performance sheet loaded, you'll get three different summaries for the good, flat, and down weeks, and the tone should shift between them. Check the Slack channel.

![Section 2 test result](screenshots/section2-test.png)

**Section 3.** Copy the webhook URL from the "Incoming message" node, then send it one of the test payloads in `sample-data/webhook-payloads.md` (there's a ready curl command in there). The draft shows up on Telegram with buttons. Tap Approve on one and Reject on another, and confirm the approved one carries on down the "Send" path while the rejected one stops at "Discard". Test both, since the reject path matters as much as the approve path.

![Section 3 test result](screenshots/section3-test.png)

**Section 4.** Add a row to your "New Clients" sheet (use one of the rows in `sample-data/new-clients-sheet.csv`). A Drive folder, a Notion page, and a Slack message should all appear. Add the second row to confirm it handles more than one, and re-run to confirm it doesn't duplicate the ones already done.

![Section 4 test result](screenshots/section4-test.png)

## Troubleshooting

These are the things that actually tripped me up building it, so you can skip the head-scratching.

**A trigger doesn't fire when you drop a file / add a row.** The Drive and Sheets triggers (Sections 1 and 4) only react to things that happen *after* the workflow is active, and when you first publish, they set a marker at "now" and ignore everything older. So the file you added five minutes ago won't get picked up. Publish first, then add the file/row. For testing without publishing, use the "Fetch Test Event" button on the trigger node, then Execute.

**The AI's category or tags come back blank / nothing matches.** If you're on a "thinking" model (Gemini's newer ones), the node returns two parts: the model's reasoning and then the actual answer. If you read the first part you get the reasoning blob and nothing matches. The expressions here already handle this by filtering out the thought part (`.parts.filter(p => !p.thought).pop().text`). If you swap in a different model and things break, that's the first place to look.

**Google Sheets or Notion "Document/Database is required," or the dropdown is empty.** Two usual causes: the credential is signed into the wrong Google account (the sheet lives in a different Drive than the one the credential can see), or, for Notion, you created the integration but forgot to share the database with it. In Notion, open the database, hit the ••• menu, Connections, and add your integration. Nothing works until that share is done.

**Slack "channel" dropdown shows no results.** The bot token needs the `channels:read` scope, and scopes only take effect after you reinstall the app. Add the scope, click Reinstall, then paste the fresh token back into n8n (the token changes on reinstall). Or skip all that and set the channel "By ID" — grab the channel ID from Slack (open the channel, click its name, it's at the bottom). Posting only needs `chat:write` plus the bot being invited to the channel (`/invite @yourbot`).

**Telegram draft never arrives.** Two things: you have to message the bot first (a bot can't start a conversation with you), and the "Send and Wait" step needs the workflow published to hold the wait properly. If you're testing, publish it, then hit the production webhook URL rather than the test one.

**"invalid syntax" on an expression.** Usually a doubled-up expression, e.g. `{{ ... {{ ... }} ... }}`. n8n expressions can't nest. One set of `{{ }}` per field.

## What this actually is

This is a practice and portfolio project, built to show a pattern, not a product sold to a client. All the data in it is invented. The clients, the numbers, the messages, none of it is real.

One substitution worth calling out: Section 3 uses a plain webhook to represent an incoming comment or DM. A lot of social platforms and agency tools expose their inbound messages over a webhook or API, so the pattern is the same everywhere, only the connection details change. To run this against a specific platform for real, you'd swap that generic webhook for that platform's own trigger, and swap the "Send approved reply" placeholder for its send API. The middle of the workflow (draft, approve, gate) stays exactly as it is.

Questions? Open an issue.
