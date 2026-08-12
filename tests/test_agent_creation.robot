*** Settings ***
Documentation     Covers agent creation and the pending-agent approval gate from the QA guide.
...                AUTH NOTE: same as dashboard suite - uses session-cookie injection since
...                the account is Google OAuth only. Set SESSION_COOKIE_VALUE before running.
Resource          ../resources/ubuntu_voice_common.resource
Test Setup        Open Ubuntu Voice Browser Authenticated
Test Teardown     Close Ubuntu Voice Browser


*** Test Cases ***
Create Agent Page Loads With Required Fields
    [Tags]    smoke    agent
    Open New Agent Form
    Page Should Contain Element    ${AGENT_NAME_INPUT}
    Page Should Contain Element    ${AGENT_EMAIL_INPUT}
    Page Should Contain Element    ${AGENT_PHONE_INPUT}
    Page Should Contain Element    ${AGENT_PURPOSE_INPUT}

A New Agent Can Be Created And Starts Unapproved
    [Documentation]    Confirms agent creation succeeds and the new agent correctly starts
    ...                in an Unapproved state, matching the QA guide's approval-gating rule.
    [Tags]    agent    regression
    ${timestamp}=    Get Time    epoch
    ${agent_name}=    Set Variable    Test Agent ${timestamp}
    Create Agent    ${agent_name}    testagent${timestamp}@example.com    purpose=Automated test agent
    Agent Should Appear In List As Unapproved    ${agent_name}

A Pending Agent Does Not Appear In The Public Chat Picker
    [Documentation]    QA guide rule: unapproved agents must not be selectable by the public.
    ...                This is the highest-value test in this suite - a leak here would let
    ...                unvetted, unreviewed agents give guidance to real users in crisis.
    [Tags]    agent    security    critical    regression
    ${timestamp}=    Get Time    epoch
    ${agent_name}=    Set Variable    Test Agent ${timestamp}
    Create Agent    ${agent_name}    testagent${timestamp}@example.com
    Agent Should Appear In List As Unapproved    ${agent_name}
    Pending Agent Should Not Appear In Public Chat Picker    ${agent_name}
