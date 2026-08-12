*** Settings ***
Documentation     Page object for agent creation + document upload flow. PLACEHOLDER locators.
Library           SeleniumLibrary
Resource          ../config.resource
Resource          chat_page.resource


*** Variables ***
${CREATE_AGENT_URL}          ${BASE_URL}/agents/new
${AGENT_NAME_INPUT}          css:input[name="name"]
${AGENT_EMAIL_INPUT}         css:input[name="contactEmail"], input[name="email"]
${AGENT_PHONE_INPUT}         css:input[name="phone"]
${AGENT_DESCRIPTION_INPUT}   css:textarea[name="description"]
${AGENT_SUBMIT_BUTTON}       xpath://button[@type="submit"]
${DOCUMENT_UPLOAD_INPUT}     css:input[type="file"]
${AGENT_STATUS_BADGE}        css:[data-testid="agent-status"]
${PUBLIC_AGENT_LIST}         css:[data-testid="agent-list"]


*** Keywords ***
Go To Create Agent Page
    Go To    ${CREATE_AGENT_URL}
    Wait Until Page Contains Element    ${AGENT_NAME_INPUT}    timeout=${EXPLICIT_WAIT}

Create Agent
    [Documentation]    Fills and submits the new agent form. Requires the caller to already
    ...                be logged in (call Log In As Test User first).
    [Arguments]    ${name}    ${contact_email}    ${description}
    Go To Create Agent Page
    Input Text      ${AGENT_NAME_INPUT}    ${name}
    Input Text      ${AGENT_EMAIL_INPUT}    ${contact_email}
    Input Text      ${AGENT_DESCRIPTION_INPUT}    ${description}
    Click Button    ${AGENT_SUBMIT_BUTTON}

Upload Document For Agent
    [Documentation]    Uploads a PDF via the file input. Requires an absolute file path -
    ...                relative paths are unreliable across different machines running the suite.
    [Arguments]    ${absolute_file_path}
    Choose File    ${DOCUMENT_UPLOAD_INPUT}    ${absolute_file_path}

Agent Should Be Pending
    Wait Until Page Contains Element    ${AGENT_STATUS_BADGE}    timeout=${EXPLICIT_WAIT}
    Element Text Should Be    ${AGENT_STATUS_BADGE}    Pending

Pending Agent Should Not Appear In Public Directory
    [Documentation]    Verifies the QA guide's rule: an agent creator cannot make an agent
    ...                public without admin approval - so it must not leak into the public list.
    [Arguments]    ${agent_name}
    Go To Chat Page
    Page Should Not Contain Element    xpath://*[@data-testid="agent-list"]//*[contains(., "${agent_name}")]
