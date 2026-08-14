# Ubuntu Voice — Robot Framework Automation

Automated test suite for https://ubuntuvoice.agentrixx.com using Robot Framework +
SeleniumLibrary. Built as part of the Andela Bug Hunt Challenge.

27 test cases across 6 suites, covering authentication, public chat, dashboard/admin
security, agent creation, evaluations, and safety guardrails.

---

## Table of contents

1. [Prerequisites](#prerequisites)
2. [Project setup from scratch](#project-setup-from-scratch)
3. [Folder structure](#folder-structure)
4. [Understanding the locators](#understanding-the-locators)
5. [Authentication strategy](#authentication-strategy)
6. [Running the test suites](#running-the-test-suites)
7. [Troubleshooting](#troubleshooting)
8. [Known bugs this suite intentionally reproduces](#known-bugs-this-suite-intentionally-reproduces)
9. [What's covered vs. not covered](#whats-covered-vs-not-covered)

---

## Prerequisites

- Python 3.10+ installed
- Google Chrome installed (Windows, if running via WSL — see note below)
- Git
- If running inside WSL: Chrome itself runs on the Windows side, launched via a
  Windows-compatible chromedriver. You do NOT need a Linux build of Chrome inside WSL.

---

## Project setup from scratch

If you're cloning this repo fresh, or setting up an equivalent project from nothing:

```bash
# 1. Clone (or create) the project folder
git clone <this-repo-url> ubuntuvoice-automation
cd ubuntuvoice-automation

# 2. Create a virtual environment
python3 -m venv appium-venv

# 3. Activate it
source appium-venv/bin/activate        # Mac/Linux/WSL
# appium-venv\Scripts\activate         # Windows CMD
# appium-venv\Scripts\Activate.ps1     # Windows PowerShell

# 4. Install dependencies
pip install -r requirements.txt

# 5. Verify Robot Framework is installed correctly
robot --version
```

You should see output like `Robot Framework 7.x`. If you get "command not found," make
sure your virtual environment is actually activated (your terminal prompt should show
`(appium-venv)` at the start of the line).

### First-time sanity check

Before touching the real site, confirm everything parses correctly with a dry run
(this does NOT open a browser or touch the network — it just checks that every keyword
and import resolves):

```bash
robot --dryrun --outputdir /tmp/dryrun tests/
```

You should see `27 tests, 27 passed, 0 failed`. If anything fails here, it's a code
problem (typo, broken import, misplaced keyword) — fix that before trying a real run.

---

## Folder structure

```
ubuntuvoice-automation/
├── resources/
│   ├── config.resource                  # URLs, browser capabilities, credential variables
│   ├── ubuntu_voice_common.resource     # single import point - pulls in all page objects
│   └── pages/
│       ├── login_page.resource
│       ├── register_page.resource
│       ├── chat_page.resource
│       ├── dashboard_page.resource
│       ├── agent_page.resource
│       └── evaluations_page.resource
├── tests/
│   ├── test_authentication.robot        # login, register, logout
│   ├── test_public_chat.robot           # no-login chat flow, agent switching
│   ├── test_dashboard_and_admin.robot   # admin gating, statistics sanitization
│   ├── test_agent_creation.robot        # agent creation, approval gating
│   ├── test_evaluations.robot           # evaluations page structure
│   └── test_safety_guardrails.robot     # medical/legal/security advice checks
├── requirements.txt
├── .gitignore
└── results/                             # robot --outputdir target (gitignored, regenerated
                                          # every run - never commit this except the one
                                          # required log.html for submission, see below)
```

Every `.resource` file follows the Page Object Model: locators and low-level keywords
live in `resources/pages/`, actual test logic lives in `tests/`. No test file talks to
Selenium directly — it only calls keywords like `Log In As Test User` or
`Ask Agent And Get Response`.

---

## Understanding the locators

This site is a Next.js app with client-side rendered auth (Clerk). That means the real
DOM only exists after JavaScript hydrates in a live browser — you cannot get real
locators from `curl` or `view-source`, only from an actual browser's DevTools.

**Every locator in this repo is real and was individually confirmed via live DevTools
inspection** — none are guesses left unverified. If you extend this suite with new
pages/elements, follow the same process:

1. Open the target page in Chrome
2. Right-click the element → Inspect
3. Prefer, in order: `id` > `name`/`data-testid` > stable `class` > `placeholder` text >
   visible text content
4. Avoid absolute XPath (`/html/body/div[3]/...`) — it breaks on any layout change

---

## Authentication strategy

This was the hardest part of building this suite, worth explaining so you don't
re-solve it from scratch.

**The problem:** the test account uses Google OAuth (no password), so there's no login
*form* Selenium can fill in for authenticated test suites. We also tried reusing a real
logged-in Chrome profile directly — this reliably fails, because current Chrome
versions block automation tools from relaunching a profile that has a real, signed-in
session (a deliberate security restriction, not a bug in this setup).

**The solution: session cookie injection.** Instead of logging in, we launch a
completely fresh, disposable Chrome session and inject a real session cookie value
directly, tricking the site into treating it as already authenticated.

### How to get a fresh session cookie value

Cookie values expire roughly every 7 days (per the JWT's `exp` claim), so you'll need
to repeat this periodically:

1. Log into https://ubuntuvoice.agentrixx.com normally in any browser (Google OAuth is
   fine)
2. Open DevTools (`Ctrl+Shift+I`, or right-click → Inspect if F12 is remapped to
   something else on your keyboard)
3. Go to **Application** tab → **Storage** → **Cookies** →
   `https://ubuntuvoice.agentrixx.com`
4. Find the cookie named `ubuntu_voice_session`
5. Copy its **value** column (a long string starting with `eyJ...` — this is a JWT)

**Never paste this value into a chat, commit it to git, or share it anywhere public.**
It's equivalent to your password — anyone with it can access your account. Treat it
like a secret, use it only via environment variables in your own terminal.

### Using it

```bash
export SESSION_COOKIE_VALUE='paste_your_real_value_here'
```

Any suite whose `Test Setup` calls `Open Ubuntu Voice Browser Authenticated` will pick
this up automatically. Suites that don't need auth (public chat, registration) don't
need this variable set at all.

---

## Running the test suites

Always activate your virtual environment first: `source appium-venv/bin/activate`

### Suites that don't need authentication

```bash
robot --outputdir results tests/test_public_chat.robot
robot --outputdir results tests/test_authentication.robot
robot --outputdir results tests/test_safety_guardrails.robot
```

`test_authentication.robot` additionally supports (but doesn't require) real test
credentials for the login-form-specific tests:

```bash
robot --outputdir results \
  --variable TEST_USER_EMAIL:youraccount@example.com \
  --variable TEST_USER_PASSWORD:yourpassword \
  tests/test_authentication.robot
```

If you don't pass these, the 4 tests that need them will `SKIP` gracefully rather than
fail — this is expected on this particular deployment, see
[Known bugs](#known-bugs-this-suite-intentionally-reproduces) below for why.

### Suites that need authentication (session cookie)

```bash
export SESSION_COOKIE_VALUE='your_real_cookie_value'
robot --outputdir results tests/test_dashboard_and_admin.robot
robot --outputdir results tests/test_agent_creation.robot
robot --outputdir results tests/test_evaluations.robot
```

### Run everything at once

```bash
export SESSION_COOKIE_VALUE='your_real_cookie_value'
robot --outputdir results tests/
```

### Viewing results

After any run, open `results/log.html` in a browser. This is the most useful debugging
tool in Robot Framework — it shows every keyword executed, timing, and (critically) an
**automatic screenshot embedded at the exact moment of any failure**. Always check this
before assuming a locator is wrong; often it reveals the real issue faster than
re-guessing (e.g. a collapsed UI section, a redirect you didn't expect, etc.).

---

## Troubleshooting

### `SessionNotCreatedException` / `Runtime.evaluate wasn't found` / mentions a Chrome
version number in the error

This is a Chrome/chromedriver version mismatch — Chrome auto-updated past what your
installed driver supports. Fix:

```bash
pip install --upgrade selenium
rm -rf ~/.cache/selenium
```

Then re-run. This suite avoids the most common trigger for this error (the JS-based
`Maximize Browser Window` keyword) by using a native `--start-maximized` launch flag
instead, but a large enough Chrome version jump can still occasionally cause this.

### `SESSION_COOKIE_VALUE not supplied`

You forgot to `export` it in *this* terminal session — it doesn't persist between
terminal windows or across reboots. Re-run the `export` command shown above.

### Tests that need auth are redirecting to `/login` instead of running

Your cookie value has likely expired (~7 days). Get a fresh one following the steps
above.

### An agent-selection test fails with "Page should have contained element ... option[value=...]"

This means a specific agent's UUID has changed or the agent no longer exists in the
approved list — this happened for real during development (the original "Somalia
Agent" was replaced by a different tester's "AgentSomalia" partway through testing).
This is a real risk of testing against a **shared sandbox environment** during an
active bug hunt competition — other testers' agents get created, renamed, or deleted
throughout the event, and admins may also approve/unapprove/remove agents at any time.

To fix it:
1. Open `/chat` on the live site and check the agent dropdown for the current real
   agent names
2. Right-click the specific `<option>` element → Inspect → note its `value` attribute
   (a UUID)
3. Update the matching `${AGENT_ID_*}` variable in `resources/pages/chat_page.resource`
   — every test references agents through these three variables, so a single change
   fixes every downstream test at once

If you're running this suite after the competition/sandbox has ended, expect this to
happen more than once — the environment is not static.

### A test fails with "Element not found" right after I changed something

1. Check `results/log.html` first — the embedded failure screenshot usually shows
   exactly what state the page was actually in.
2. Confirm you're not looking at a stale/cached copy of a `.resource` file — this repo
   went through several rounds of locator fixes during development; always make sure
   your local files match what's actually in this repo.

---

## Known bugs this suite intentionally reproduces

These aren't test defects — they're real, documented findings from the bug hunt. Full
write-ups with reproduction steps live in the submission tracker; summarized here for
context on why certain tests fail/skip on this deployment:

- **Broken email/password registration.** The verification email link points to
  `localhost` instead of the production domain, so it can never be completed
  (`ERR_CONNECTION_REFUSED`). As a knock-on effect, there is currently no way to obtain
  a working email/password test account at all — Google OAuth accounts have no
  password and no way to add one. This is why `A New Account Can Be Created With Valid
  Details` fails, and why 4 other tests in `test_authentication.robot` skip when no
  `TEST_USER_EMAIL`/`TEST_USER_PASSWORD` is supplied.
- **Medical advice guardrail gap.** The chat agent gives specific first-aid treatment
  steps (not just emergency contacts) when asked a direct medical question, despite the
  homepage's explicit claim that "the platform avoids presenting AI output as ...
  medical ... advice." See `test_safety_guardrails.robot`.
- **Missing `<title>` element on `/dashboard`.** Caught via Chrome DevTools Lighthouse,
  not this Robot Framework suite. Minor/cosmetic, documented for completeness.

---

## What's covered vs. not covered

**Automated (this repo):**
- Login, registration, logout, session invalidation
- Public chat: agent selection, grounded responses, fallback behavior, cross-agent
  scoping
- Dashboard admin gating (`/guardrails` nav visibility + direct URL blocking)
- Statistics table sanitization
- Agent creation + approval-gating (pending agents don't leak publicly)
- Evaluations page structure and question-adding flow
- Medical/legal/security advice guardrail responses (captured for manual review, not
  auto-asserted — judging "is this professional advice" isn't reliably automatable)

**Manually tested, not automated (documented via screenshots instead):**
- Multilingual support (French, Swahili) — confirmed working correctly
- Voice mode (mic input, transcription, text-to-speech) — confirmed working correctly
- Performance/accessibility (via Chrome DevTools Lighthouse, not Robot Framework)

**Not tested — genuinely out of scope for browser automation:**
- WhatsApp channel — requires QR-pairing with a real phone number; WhatsApp also
  actively detects/restricts automated behavior, so this needs manual testing only
- SMS, USSD, email pathways — would require telecom-level or inbox-level access not
  available for this bug hunt
