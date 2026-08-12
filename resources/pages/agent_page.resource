*** Settings ***
Documentation     Page object for agent creation + document upload. Locators based on visible
...                placeholder text confirmed via screenshot (real form: Agent name*, Email*,
...                Phone (optional), Purpose (optional), Create agent button - no separate
...                "description" field, unlike earlier guess).
Library           SeleniumLibrary
Resource          ../config.resource
Resource          chat_page.resource


*** Variables ***
${NEW_AGENT_BUTTON}          xpath://button[contains(., "New agent")]
${AGENT_NAME_INPUT}          css:input[placeholder*="Agent name"]
${AGENT_EMAIL_INPUT}         css:input[placeholder*="Email"]
${AGENT_PHONE_INPUT}         css:input[placeholder*="Phone"]
${AGENT_PURPOSE_INPUT}       css:input[placeholder*="Purpose" i], textarea[placeholder*="Purpose" i]
${AGENT_SUBMIT_BUTTON}       xpath://button[contains(., "Create agent")]
${AGENT_LIST_ITEM}           xpath://*[contains(text(), "%NAME%")]
${AGENT_UNAPPROVED_BADGE}    xpath://*[contains(text(), "Unapproved")]
${DOCUMENT_UPLOAD_INPUT}     css:input[type="file"]


*** Keywords ***
Go To Create Agent Page
    Go To    ${CREATE_AGENT_URL}
    Wait Until Page Contains Element    ${NEW_AGENT_BUTTON}    timeout=${EXPLICIT_WAIT}

Open New Agent Form
    Go To Create Agent Page
    Click Element    ${NEW_AGENT_BUTTON}
    Wait Until Page Contains Element    ${AGENT_NAME_INPUT}    timeout=${EXPLICIT_WAIT}

Create Agent
    [Documentation]    Fills and submits the new agent form. Phone and purpose are optional
    ...                per the real form - pass empty string to skip them.
    [Arguments]    ${name}    ${email}    ${phone}=${EMPTY}    ${purpose}=${EMPTY}
    Open New Agent Form
    Input Text      ${AGENT_NAME_INPUT}    ${name}
    Input Text      ${AGENT_EMAIL_INPUT}    ${email}
    IF    '${phone}' != ''
        Input Text    ${AGENT_PHONE_INPUT}    ${phone}
    END
    IF    '${purpose}' != ''
        Input Text    ${AGENT_PURPOSE_INPUT}    ${purpose}
    END
    Click Button    ${AGENT_SUBMIT_BUTTON}

Agent Should Appear In List As Unapproved
    [Documentation]    Confirms a newly created agent shows up in the sidebar list with the
    ...                Unapproved badge - matches the QA guide's approval-gating requirement.
    [Arguments]    ${agent_name}
    Wait Until Page Contains    ${agent_name}    timeout=${EXPLICIT_WAIT}
    Page Should Contain Element    ${AGENT_UNAPPROVED_BADGE}

Upload Document For Agent
    [Documentation]    Uploads a file via the file input. Requires an agent already selected
    ...                in the sidebar and an absolute file path.
    [Arguments]    ${absolute_file_path}
    Choose File    ${DOCUMENT_UPLOAD_INPUT}    ${absolute_file_path}

Pending Agent Should Not Appear In Public Chat Picker
    [Documentation]    QA guide rule: an unapproved agent must not be selectable by the
    ...                public until an admin approves it. Checks the /chat dropdown options
    ...                by visible name, not by UUID (since a new agent's UUID isn't known
    ...                until it's approved and inspected).
    [Arguments]    ${agent_name}
    Go To Chat Page
    Page Should Not Contain Element    xpath://option[contains(text(), "${agent_name}")]
