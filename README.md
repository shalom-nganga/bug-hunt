# Ubuntu Voice - Robot Framework Automation

Automation suite for https://ubuntuvoice.agentrixx.com using SeleniumLibrary.

## Structure

```
ubuntuvoice-automation/
├── resources/
│   ├── config.resource              # URLs, browser capabilities, credential variables
│   ├── ubuntu_voice_common.resource # single import point - pulls in all page objects
│   └── pages/
│       ├── login_page.resource
│       ├── chat_page.resource
│       ├── dashboard_page.resource
│       └── agent_page.resource
├── tests/
│   ├── test_public_chat.robot
│   ├── test_authentication.robot
│   └── test_dashboard_and_admin.robot
├── requirements.txt
└── results/                         # robot --outputdir target (gitignored)
```

## IMPORTANT - before running anything

Every locator in `resources/pages/*.resource` is a **placeholder**. This is a Next.js app
with client-side rendered auth (Clerk) - the real DOM only exists after JavaScript hydrates
in a live browser. Static fetching (curl, requests, etc.) will never show you the real
elements. Same rule as the Appium Clock assignment: **inspect the live DOM yourself, don't
trust guessed locators.**

To fix a locator:
1. Open the page in Chrome.
2. Right-click the element → Inspect.
3. Note a stable attribute (id, name, data-testid, aria-label - in that order of preference).
4. Update the corresponding `${VARIABLE}` in the relevant `.resource` file.

## Setup

```bash
python3 -m venv appium-venv
source appium-venv/bin/activate       # Windows: appium-venv\Scripts\activate
pip install -r requirements.txt
```

You also need a Chrome + matching chromedriver on PATH (Selenium 4 usually manages this
automatically via Selenium Manager - run `python3 -m pip show selenium` to confirm version).

## Running

Never hardcode real credentials into `.resource` files. Pass them at runtime:

```bash
robot --outputdir results \
  --variable TEST_USER_EMAIL:youraccount@example.com \
  --variable TEST_USER_PASSWORD:yourpassword \
  --variable ADMIN_USER_EMAIL:admin@example.com \
  --variable ADMIN_USER_PASSWORD:adminpassword \
  tests/
```

Or export as environment variables before running (config.resource reads them via
`%{TEST_USER_EMAIL=}` syntax, which falls back to empty string if unset):

```bash
export TEST_USER_EMAIL=youraccount@example.com
export TEST_USER_PASSWORD=yourpassword
robot --outputdir results tests/
```

Tests requiring credentials `Skip If` gracefully when none are supplied, rather than failing
on empty-string input against a real login form.

## Dry-run (syntax check only, no browser needed)

```bash
robot --dryrun --outputdir /tmp/dryrun tests/
```

Useful for catching typos/broken imports before spending time on real locator work.

## What's covered vs. what's still needed

**Covered (skeleton ready, needs real locators):**
- Public chat: page load, greeting, grounded-doc question, out-of-scope fallback safety check
- Auth: login page load, valid login, invalid password, register link
- Dashboard/admin: guardrails nav visibility, direct-URL admin gating (the most valuable
  security test in this suite), statistics sanitization check

**Not yet scaffolded - add as separate suites once the above locators are verified:**
- Full agent creation + document upload + evaluation flow (`agent_page.resource` has the
  keywords, just needs a `test_agent_creation.robot` suite)
- Incident reporting → statistics row creation/count-increment (QA guide workflow checks
  3-6: single category, multi-category, repeated report, unknown place)
- Pending agent visibility check (`Pending Agent Should Not Appear In Public Directory`
  keyword exists in `agent_page.resource`, unused so far)

## Notes

- No `Sleep` used anywhere - all waits are `Wait Until Page Contains Element` or
  `Wait Until Keyword Succeeds` polling, per good RF practice.
- `Test Teardown Close Ubuntu Voice Browser` runs unconditionally in every suite, so no
  browser sessions leak between test cases even on failure.
