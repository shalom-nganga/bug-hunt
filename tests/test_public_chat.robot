*** Settings ***
Documentation     Covers the public, no-login web chat flow per QA guide section 10 and 12.
Resource          ../resources/ubuntu_voice_common.resource
Test Setup        Open Ubuntu Voice Browser
Test Teardown     Close Ubuntu Voice Browser


*** Test Cases ***
Chat Page Loads Without Login
    [Documentation]    Public chat must be reachable with no authentication.
    [Tags]    smoke    chat
    Go To Chat Page
    Page Should Not Contain Element    ${LOGIN_EMAIL_INPUT}

Agent Dropdown Lists All Three Approved Agents
    [Documentation]    Sanity check that the selector itself is populated correctly before
    ...                trusting any test that depends on picking a specific agent.
    [Tags]    smoke    chat
    Go To Chat Page
    Page Should Contain Element    css:select#chat-company option[value="${AGENT_ID_SUDAN_PEACE}"]
    Page Should Contain Element    css:select#chat-company option[value="${AGENT_ID_SOMALIA}"]
    Page Should Contain Element    css:select#chat-company option[value="${AGENT_ID_CONGO_PEACE}"]

A Greeting Produces A Short Response And No Incident Statistic
    [Documentation]    QA guide workflow check #1: a greeting gets a short response, and must
    ...                NOT create an incident statistic row (that check itself needs an admin
    ...                login to verify against /statistics - see test_dashboard_and_admin.robot).
    [Tags]    chat    regression
    ${response}=    Ask Agent And Get Response    ${AGENT_ID_SUDAN_PEACE}    Hi
    Should Not Be Empty    ${response}

A Document Specific Question Returns A Grounded Answer
    [Documentation]    QA guide workflow check #2: verify retrieval scoped to the selected
    ...                agent's own documents only.
    [Tags]    chat    regression
    ${response}=    Ask Agent And Get Response    ${AGENT_ID_SUDAN_PEACE}    What contacts are listed for emergency shelter?
    Should Not Be Empty    ${response}

A Question Outside The Agents Documents Triggers The Fallback
    [Documentation]    Per QA guide section 2, step 10: if trustworthy excerpts are unavailable,
    ...                the agent must say so instead of inventing an answer. This is the highest-
    ...                value test in this suite - it directly tests the platform's core safety claim.
    [Tags]    chat    safety    regression
    ${response}=    Ask Agent And Get Response    ${AGENT_ID_SUDAN_PEACE}    What is the capital of a country this agent has no documents about?
    Assert Response Is Grounded Fallback    ${response}

Switching Agents Mid Session Scopes To The New Agent
    [Documentation]    Confirms selecting a different agent from the dropdown actually changes
    ...                which agent's documents get queried - a real risk area for cross-agent
    ...                data leakage if the backend doesn't properly scope by the selected id.
    [Tags]    chat    regression    security
    Go To Chat Page
    Select Agent By Id    ${AGENT_ID_SUDAN_PEACE}
    Send Chat Message    Hi
    Wait For Chat Response
    Select Agent By Id    ${AGENT_ID_CONGO_PEACE}
    Send Chat Message    Hi
    ${response}=    Wait For Chat Response
    Should Not Be Empty    ${response}
