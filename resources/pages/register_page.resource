*** Settings ***
Documentation     Page object for /register. Locators verified against the live DOM
...               (not placeholders - confirmed via browser inspection).
Library           SeleniumLibrary
Resource          ../config.resource


*** Variables ***
${REGISTER_FIRST_NAME_INPUT}     css:input[name="first_name"]
${REGISTER_LAST_NAME_INPUT}      css:input[name="last_name"]
${REGISTER_EMAIL_INPUT}          css:input[name="email"]
${REGISTER_PASSWORD_INPUT}       css:input[name="password"]
${REGISTER_CONFIRM_PASSWORD_INPUT}    css:input[name="confirm_password"]
${REGISTER_SUBMIT_BUTTON}        css:form.space-y-4 button[type="submit"]
${REGISTER_GOOGLE_BUTTON}        xpath://a[contains(., "Continue with Google")]
${REGISTER_SIGNIN_LINK}          css:p.text-center a[href*="login"]
${REGISTER_PAGE_HEADER}          xpath://h1[contains(text(), "Create your account")]


*** Keywords ***
Go To Register Page
    Go To    ${REGISTER_URL}
    Wait Until Page Contains Element    ${REGISTER_PAGE_HEADER}    timeout=${EXPLICIT_WAIT}

Register New Account
    [Documentation]    Fills the full registration form and submits. Caller is responsible
    ...                for generating a unique email per test run (see Generate Unique Test Email
    ...                below) so repeated test runs don't collide on an already-registered address.
    [Arguments]    ${first_name}    ${last_name}    ${email}    ${password}
    Go To Register Page
    Input Text        ${REGISTER_FIRST_NAME_INPUT}    ${first_name}
    Input Text        ${REGISTER_LAST_NAME_INPUT}    ${last_name}
    Input Text        ${REGISTER_EMAIL_INPUT}    ${email}
    Input Text        ${REGISTER_PASSWORD_INPUT}    ${password}
    Input Text        ${REGISTER_CONFIRM_PASSWORD_INPUT}    ${password}
    Click Button       ${REGISTER_SUBMIT_BUTTON}

Generate Unique Test Email
    [Documentation]    Builds a timestamp-based email so account-creation tests are
    ...                repeatable without manually deleting the previous test account first.
    ${timestamp}=    Get Time    epoch
    RETURN    robotuser+${timestamp}@example.com

Click Sign In Link From Register Page
    Go To Register Page
    Click Element    ${REGISTER_SIGNIN_LINK}
