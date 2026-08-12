*** Settings ***
Documentation     Page object for /login.
...               NOTE: This site is a Next.js app with client-side rendered auth (likely Clerk).
...               Elements do NOT exist in the raw HTML - they render after JS hydrates.
...               Every locator below is a PLACEHOLDER based on common patterns. Before running
...               any test, open /login in Chrome, hit F12 -> Inspect on each real element, and
...               replace the locator value with what you actually find. Do not trust these blindly.
Library           SeleniumLibrary
Resource          ../config.resource


*** Variables ***
# --- Placeholders: verify against live DOM before use ---
${LOGIN_EMAIL_INPUT}         css:input[type="email"], input[name="email"], input[placeholder*="email" i]
${LOGIN_PASSWORD_INPUT}      css:input[type="password"], input[name="password"]
${LOGIN_SUBMIT_BUTTON}       xpath://button[contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'sign in') or contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'log in')]
${LOGIN_ERROR_MESSAGE}       css:[role="alert"], .cl-formFieldErrorText, .error-message
${REGISTER_LINK}             xpath://a[contains(@href, "/register")]
${GOOGLE_SIGNIN_BUTTON}      xpath://button[contains(., "Google")]


*** Keywords ***
Go To Login Page
    Go To    ${LOGIN_URL}
    Wait Until Page Contains Element    ${LOGIN_EMAIL_INPUT}    timeout=${EXPLICIT_WAIT}

Log In As
    [Documentation]    Fills email + password and submits. Fails loudly if fields aren't found -
    ...                that failure itself is useful signal (locator drift or auth flow changed).
    [Arguments]    ${email}    ${password}
    Go To Login Page
    Input Text      ${LOGIN_EMAIL_INPUT}    ${email}
    Input Text      ${LOGIN_PASSWORD_INPUT}    ${password}
    Click Button    ${LOGIN_SUBMIT_BUTTON}

Log In As Test User
    Log In As    ${TEST_USER_EMAIL}    ${TEST_USER_PASSWORD}

Log In As Admin User
    Log In As    ${ADMIN_USER_EMAIL}    ${ADMIN_USER_PASSWORD}

Assert Login Error Is Shown
    Wait Until Page Contains Element    ${LOGIN_ERROR_MESSAGE}    timeout=${EXPLICIT_WAIT}

Assert Login Succeeded
    [Documentation]    Login should redirect away from /login on success. Adjust target URL
    ...                once you confirm the real post-login redirect (dashboard? chat? home?).
    Wait Until Keyword Succeeds    ${EXPLICIT_WAIT}    1s    Location Should Not Contain Login

Location Should Not Contain Login
    [Documentation]    Helper used by Wait Until Keyword Succeeds - SeleniumLibrary has no
    ...                built-in "wait until URL changes" keyword, so this polls Get Location.
    ${current}=    Get Location
    Should Not Contain    ${current}    /login
