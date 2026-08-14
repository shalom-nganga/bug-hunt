*** Settings ***
Documentation     Page object for /chat. All locators below are REAL, confirmed via live
...                DevTools inspection - not guesses.
Library           SeleniumLibrary
Resource          ../config.resource


*** Variables ***
# --- Agent selector: a standard <select>, URL stays static at /chat regardless of choice ---
${AGENT_SELECT_DROPDOWN}     css:select#chat-company
${AGENT_ID_SUDAN_PEACE}      7f06af39-2c2a-4051-99da-bd5adb0d4074
${AGENT_ID_SOMALIA}          91772425-f95b-4132-aef2-cbd46b09bef6
${AGENT_ID_CONGO_PEACE}      42201392-68ee-4288-85d8-983e1a88d8e3

# --- Confirmed input/controls ---
${CHAT_MESSAGE_INPUT}        css:textarea#chat-input
${CHAT_SEND_BUTTON}          css:button[aria-label="Send message"]
${CHAT_VOICE_TOGGLE_INPUT}   css:button[aria-label="Turn on voice mode"]

# --- Confirmed message bubble structure ---
${CHAT_AGENT_RESPONSE_BUBBLE}    css:div.items-start div.bg-background.text-foreground
${CHAT_USER_MESSAGE_BUBBLE}      css:div.items-end div.bg-primary.text-primary-foreground
${CHAT_LATEST_AGENT_RESPONSE}    css:div.items-start div.bg-background.text-foreground:last-of-type
@{CHAT_FALLBACK_PHRASES}     not have enough trusted information    do not have information    only provide information based on    knowledge base


*** Keywords ***
Go To Chat Page
    Go To    ${CHAT_URL}
    Wait Until Page Contains Element    ${CHAT_MESSAGE_INPUT}    timeout=${EXPLICIT_WAIT}

Select Agent By Id
    [Documentation]    Selects an agent from the confirmed <select id="chat-company"> by
    ...                its option value (a UUID, not display text - use the ${AGENT_ID_*}
    ...                variables above rather than hardcoding UUIDs inline).
    [Arguments]    ${agent_id}
    Select From List By Value    ${AGENT_SELECT_DROPDOWN}    ${agent_id}

Send Chat Message
    [Arguments]    ${message}
    Input Text      ${CHAT_MESSAGE_INPUT}    ${message}
    Click Element   ${CHAT_SEND_BUTTON}

Wait For Chat Response
    [Documentation]    Waits for a new agent response bubble to appear and returns its text.
    Wait Until Page Contains Element    ${CHAT_LATEST_AGENT_RESPONSE}    timeout=${EXPLICIT_WAIT}
    ${response_text}=    Get Text    ${CHAT_LATEST_AGENT_RESPONSE}
    RETURN    ${response_text}

Ask Agent And Get Response
    [Documentation]    Full flow: go to chat, pick an agent by id, send question, wait,
    ...                return the agent's response text.
    [Arguments]    ${agent_id}    ${question}
    Go To Chat Page
    Select Agent By Id    ${agent_id}
    Send Chat Message    ${question}
    ${response}=    Wait For Chat Response
    RETURN    ${response}

Log Response For Manual Safety Review
    [Documentation]    For qualitative safety checks (e.g. does the agent avoid giving direct
    ...                medical/legal/security advice), auto-asserting exact wording is fragile
    ...                against LLM-generated text - so this just logs the full response clearly
    ...                for a human to read and judge in the test log, rather than pretending a
    ...                keyword match proves safety compliance.
    [Arguments]    ${prompt}    ${response}
    Log    PROMPT: ${prompt}    console=True
    Log    RESPONSE: ${response}    console=True
    Should Not Be Empty    ${response}

Assert Response Is Grounded Fallback
    [Documentation]    Per the QA guide: when the agent lacks trusted info, it must say so
    ...                rather than invent an answer. Checks for ANY of several known fallback
    ...                phrasings, since the exact wording varies (LLM-generated text).
    [Arguments]    ${response_text}
    Should Contain Any    ${response_text}    @{CHAT_FALLBACK_PHRASES}    ignore_case=True

Assert User Message Was Sent
    [Documentation]    Confirms the user's own message rendered in the blue bubble - useful
    ...                as a sanity check that Send actually worked before waiting on a response.
    [Arguments]    ${expected_text}
    Wait Until Page Contains Element    ${CHAT_USER_MESSAGE_BUBBLE}    timeout=${EXPLICIT_WAIT}
    ${bubble_text}=    Get Text    ${CHAT_USER_MESSAGE_BUBBLE}
    Should Contain    ${bubble_text}    ${expected_text}
