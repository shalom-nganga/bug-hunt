*** Settings ***
Documentation     Covers signed-in dashboard, statistics, and the admin-only /guardrails gating
...                described in the QA guide.
...
...                AUTH NOTE: uses session-cookie injection instead of form login, since your
...                account uses Google OAuth (no password to automate). Before running, get a
...                fresh session cookie value from DevTools (Application > Cookies >
...                ubuntu_voice_session on the live site while logged in), then run:
...                export SESSION_COOKIE_VALUE='paste_value_here'
...                robot --outputdir results tests/test_dashboard_and_admin.robot
...                Never commit or paste that value anywhere outside your own terminal.
Resource          ../resources/ubuntu_voice_common.resource
Test Setup        Open Ubuntu Voice Browser Authenticated
Test Teardown     Close Ubuntu Voice Browser


*** Test Cases ***
Non Admin Does Not See Guardrails Nav Link
    [Documentation]    QA guide: "The Guardrails dashboard navigation button is shown only
    ...                to administrators." CONFIRMED LIVE via screenshot: sidebar shows
    ...                Overview, Evaluations, Statistics, Known Places only - no Guardrails.
    [Tags]    dashboard    security    regression
    Guardrails Nav Link Should Not Be Visible

Non Admin Direct URL Access To Guardrails Is Blocked
    [Documentation]    QA guide: "non-administrators cannot access the page by entering its
    ...                URL directly." CONFIRMED LIVE: app redirects back to /dashboard rather
    ...                than showing an access-denied message.
    [Tags]    dashboard    security    critical    regression
    Direct Navigation To Guardrails Should Be Blocked

Statistics Table Does Not Leak Raw Contact Details
    [Documentation]    QA guide section 4/12 workflow check #7: a report containing a phone
    ...                number or email must have that detail sanitized out of the stored
    ...                description. Requires a report with contact info to have already been
    ...                submitted via chat first - this test only checks the stored result.
    [Tags]    dashboard    safety    critical    regression
    Statistics Table Should Not Contain    0700000000
    Statistics Table Should Not Contain    test@example.com
