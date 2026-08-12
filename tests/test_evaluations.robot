*** Settings ***
Documentation     Covers the /evaluations RAG quality-check page. Conservative first pass -
...                only structure and the add-question flow, since "Run evaluation" behavior
...                (timing, what a pending/unapproved agent does when evaluated, cost) isn't
...                understood yet. Extend once that's been manually explored.
...                AUTH NOTE: uses session-cookie injection, same as dashboard/agent suites.
Resource          ../resources/ubuntu_voice_common.resource
Test Setup        Open Ubuntu Voice Browser Authenticated
Test Teardown     Close Ubuntu Voice Browser


*** Test Cases ***
Evaluations Page Loads With Agent Selector And Empty Dataset
    [Tags]    smoke    evaluations
    Go To Evaluations Page
    Page Should Contain Element    ${EVAL_AGENT_DROPDOWN}
    Page Should Contain Element    ${EVAL_RUN_BUTTON}
    Page Should Contain Element    ${EVAL_EMPTY_STATE}

Adding A Question Increments The Dataset Count
    [Documentation]    Confirms the "X of 50 questions" counter actually updates when a
    ...                question/reference-answer pair is added - a broken counter here would
    ...                mislead anyone building out a test dataset about how much they've done.
    [Tags]    evaluations    regression
    Go To Evaluations Page
    Add Evaluation Question    What is the capital of Sudan?    Khartoum (context-dependent test question)
    ${count_text}=    Get Evaluation Question Count Text
    Should Contain    ${count_text}    1 of 50
