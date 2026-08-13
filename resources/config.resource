*** Settings ***
Documentation     Global configuration and capabilities for Ubuntu Voice automation.
...               All environment-specific values live here so no test case hardcodes them.
Library           SeleniumLibrary


*** Variables ***
# --- Environment ---
${BASE_URL}                https://ubuntuvoice.agentrixx.com
${LOGIN_URL}                ${BASE_URL}/login
${REGISTER_URL}             ${BASE_URL}/register
${CHAT_URL}                 ${BASE_URL}/chat
${DASHBOARD_URL}             ${BASE_URL}/dashboard
${STATISTICS_URL}            ${BASE_URL}/statistics
${EVALUATIONS_URL}           ${BASE_URL}/evaluations
${CREATE_AGENT_URL}          ${BASE_URL}/documents
${GUARDRAILS_URL}            ${BASE_URL}/guardrails

# --- Browser capabilities ---
${BROWSER}                  chrome
${BROWSER_OPTIONS}          add_argument("--start-maximized")
${IMPLICIT_WAIT}             5s
${EXPLICIT_WAIT}             10s

# --- Test credentials (DO NOT hardcode real ones here - override via env vars / CLI --variable) ---
# Populate these at runtime: robot --variable TEST_USER_EMAIL:you@example.com --variable TEST_USER_PASSWORD:secret ...
${TEST_USER_EMAIL}           %{TEST_USER_EMAIL=}
${TEST_USER_PASSWORD}        %{TEST_USER_PASSWORD=}
${ADMIN_USER_EMAIL}          %{ADMIN_USER_EMAIL=}
${ADMIN_USER_PASSWORD}       %{ADMIN_USER_PASSWORD=}

# --- Session cookie injection: workaround for Google OAuth accounts having no password.
# SESSION_COOKIE_VALUE must be set locally via environment variable at runtime - never
# paste the actual value into any file, chat, or script. Get it fresh from your browser's
# DevTools (Application > Cookies) whenever it expires (~7 days per the JWT payload).
${SESSION_COOKIE_NAME}       ubuntu_voice_session
${SESSION_COOKIE_VALUE}      %{SESSION_COOKIE_VALUE=}

# --- Optional: reuse a real, pre-authenticated Chrome profile instead of logging in via
# email/password. Needed because Google OAuth accounts have no password to automate.
# Set via: export CHROME_USER_DATA_DIR='C:\SeleniumProfile' before running robot.
${CHROME_USER_DATA_DIR}      %{CHROME_USER_DATA_DIR=}
${CHROME_PROFILE_DIRECTORY}  %{CHROME_PROFILE_DIRECTORY=Default}


*** Keywords ***
Open Ubuntu Voice Browser
    [Documentation]    Opens a normal, fresh, unauthenticated browser session against the app.
    ...                Uses --start-maximized as a native Chrome launch flag rather than the
    ...                Maximize Browser Window keyword, which relies on a JS/CDP call that
    ...                breaks whenever Chrome auto-updates ahead of the installed chromedriver
    ...                (seen repeatedly as "Runtime.evaluate wasn't found" errors).
    Open Browser    ${BASE_URL}    ${BROWSER}    options=${BROWSER_OPTIONS}
    Set Selenium Implicit Wait    ${IMPLICIT_WAIT}

Close Ubuntu Voice Browser
    [Documentation]    Tears down the browser session. Call this in every suite/test teardown.
    Close All Browsers

Open Ubuntu Voice Browser Authenticated
    [Documentation]    Opens a fresh browser and injects a real session cookie to skip login
    ...                entirely - workaround for Google OAuth accounts having no password to
    ...                automate. SESSION_COOKIE_VALUE must be set locally via environment
    ...                variable before running (never hardcoded here - see README). Cookie
    ...                value expires roughly every 7 days and needs refreshing from DevTools.
    Open Ubuntu Voice Browser
    Go To    ${BASE_URL}
    IF    '${SESSION_COOKIE_VALUE}' == ''
        Fail    SESSION_COOKIE_VALUE not supplied - pass via --variable or export it before running
    END
    Add Cookie    ${SESSION_COOKIE_NAME}    ${SESSION_COOKIE_VALUE}    domain=ubuntuvoice.agentrixx.com    path=/
    Go To    ${DASHBOARD_URL}
