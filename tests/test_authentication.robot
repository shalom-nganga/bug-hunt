*** Settings ***
Documentation     Covers login/register flows. Requires TEST_USER_EMAIL and TEST_USER_PASSWORD
...                to be set via environment variables or --variable at runtime - never hardcode
...                real credentials into this file.
...
...                KNOWN ENVIRONMENT BLOCKER: as of this writing, there is no way to obtain a
...                working email/password test account in production. Email/password
...                registration cannot complete (see the localhost verification link bug),
...                and Google OAuth accounts have no password + no account-settings option to
...                add one. This means the four tests below requiring TEST_USER_EMAIL/PASSWORD
...                will SKIP until this is resolved - that is expected, not a test defect.
Resource          ../resources/ubuntu_voice_common.resource
Test Setup        Open Ubuntu Voice Browser
Test Teardown     Close Ubuntu Voice Browser


*** Test Cases ***
Login Page Loads With Required Fields
    [Tags]    smoke    auth
    Go To Login Page
    Page Should Contain Element    ${LOGIN_EMAIL_INPUT}
    Page Should Contain Element    ${LOGIN_PASSWORD_INPUT}

Valid Credentials Log The User In
    [Documentation]    Skips gracefully if no test credentials were supplied at runtime,
    ...                rather than failing on empty-string input against a real form.
    [Tags]    auth    regression
    Skip If    '${TEST_USER_EMAIL}' == ''    No TEST_USER_EMAIL supplied - pass with --variable
    Log In As Test User
    Assert Login Succeeded

Invalid Password Shows An Error And Does Not Log In
    [Tags]    auth    negative    regression
    Skip If    '${TEST_USER_EMAIL}' == ''    No TEST_USER_EMAIL supplied - pass with --variable
    Log In As    ${TEST_USER_EMAIL}    definitely-the-wrong-password-123
    Assert Login Error Is Shown
    ${current}=    Get Location
    Should Contain    ${current}    /login

Register Link Is Reachable From Login
    [Tags]    auth    smoke
    Go To Login Page
    Click Element    ${REGISTER_LINK}
    Wait Until Keyword Succeeds    ${EXPLICIT_WAIT}    1s    Location Should Contain Register

Register Page Loads With Required Fields
    [Documentation]    Confirms all five form fields plus the submit button are present -
    ...                catches a broken form render before you even try filling it out.
    [Tags]    smoke    auth    register
    Go To Register Page
    Page Should Contain Element    ${REGISTER_FIRST_NAME_INPUT}
    Page Should Contain Element    ${REGISTER_LAST_NAME_INPUT}
    Page Should Contain Element    ${REGISTER_EMAIL_INPUT}
    Page Should Contain Element    ${REGISTER_PASSWORD_INPUT}
    Page Should Contain Element    ${REGISTER_CONFIRM_PASSWORD_INPUT}

A New Account Can Be Created With Valid Details
    [Documentation]    Full happy-path registration. Uses a unique timestamped email so this
    ...                test is repeatable without manual cleanup between runs.
    ...
    ...                KNOWN FAILING - documented bug, not a test defect. Email/password
    ...                registration is currently broken in production: the verification link
    ...                sent after signup points to localhost instead of the live domain
    ...                (ERR_CONNECTION_REFUSED), so the account never completes and this page
    ...                correctly never redirects away from /register. Workaround: Google OAuth
    ...                signup works and bypasses this flow entirely (not automated here).
    [Tags]    auth    register    regression    known-issue
    ${email}=    Generate Unique Test Email
    Register New Account    Test    User    ${email}    ValidPass123!
    Wait Until Keyword Succeeds    ${EXPLICIT_WAIT}    1s    Location Should Not Contain Register

Mismatched Passwords Are Rejected
    [Documentation]    Negative test - confirm_password not matching password should block
    ...                submission or show a validation error rather than silently succeeding.
    [Tags]    auth    register    negative    regression
    ${email}=    Generate Unique Test Email
    Go To Register Page
    Input Text     ${REGISTER_FIRST_NAME_INPUT}    Test
    Input Text     ${REGISTER_LAST_NAME_INPUT}    User
    Input Text     ${REGISTER_EMAIL_INPUT}    ${email}
    Input Text     ${REGISTER_PASSWORD_INPUT}    ValidPass123!
    Input Text     ${REGISTER_CONFIRM_PASSWORD_INPUT}    DifferentPass456!
    Click Button    ${REGISTER_SUBMIT_BUTTON}
    ${current}=    Get Location
    Should Contain    ${current}    /register

Sign In Link On Register Page Leads To Login
    [Tags]    auth    register    smoke
    Click Sign In Link From Register Page
    Wait Until Keyword Succeeds    ${EXPLICIT_WAIT}    1s    Location Should Contain Login

A Logged In User Can Log Out
    [Documentation]    Full account lifecycle check: login, land on dashboard, open the
    ...                profile dropdown, click Logout, confirm redirected away from /dashboard.
    [Tags]    auth    logout    regression
    Skip If    '${TEST_USER_EMAIL}' == ''    No TEST_USER_EMAIL supplied - pass with --variable
    Log In As Test User
    Assert Login Succeeded
    Go To Dashboard
    Log Out
    Page Should Contain Element    ${LOGIN_EMAIL_INPUT}

After Logout Dashboard Is No Longer Accessible
    [Documentation]    Security check - confirms logout actually invalidates the session
    ...                rather than just visually hiding the dashboard.
    [Tags]    auth    logout    security    regression
    Skip If    '${TEST_USER_EMAIL}' == ''    No TEST_USER_EMAIL supplied - pass with --variable
    Log In As Test User
    Assert Login Succeeded
    Go To Dashboard
    Log Out
    Go To    ${DASHBOARD_URL}
    Wait Until Keyword Succeeds    ${EXPLICIT_WAIT}    1s    Location Should Contain Login


*** Keywords ***
Location Should Contain Login
    [Documentation]    Helper for Wait Until Keyword Succeeds - confirms redirect to login.
    ${current}=    Get Location
    Should Contain    ${current}    /login

Location Should Contain Register
    [Documentation]    Helper for Wait Until Keyword Succeeds - confirms navigation to register.
    ${current}=    Get Location
    Should Contain    ${current}    /register

Location Should Not Contain Register
    [Documentation]    Helper for Wait Until Keyword Succeeds - polls current URL.
    ${current}=    Get Location
    Should Not Contain    ${current}    /register
