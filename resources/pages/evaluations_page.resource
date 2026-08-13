*** Settings ***
Documentation     Page object for /evaluations - runs RAG quality checks against an agent's
...                test dataset. Locators based on visible placeholder/button text from
...                screenshot - not yet confirmed via DevTools element inspection.
Library           SeleniumLibrary
Resource          ../config.resource


*** Variables ***
${EVAL_AGENT_DROPDOWN}       css:select
${EVAL_RUN_BUTTON}           xpath://button[contains(., "Run evaluation")]
${EVAL_QUESTION_INPUT}       xpath://textarea[@placeholder="Question"]
${EVAL_REFERENCE_ANSWER_INPUT}    xpath://textarea[@placeholder="Reference answer"]
${EVAL_ADD_QUESTION_BUTTON}  xpath://button[contains(., "Add question")]
${EVAL_QUESTION_COUNT}       xpath://*[contains(., "of 50 questions")]
${EVAL_TEST_DATASET_HEADER}   xpath://*[contains(text(), "Test dataset")]
${EVAL_EMPTY_STATE}          xpath://*[contains(text(), "Add questions and run the first evaluation")]


*** Keywords ***
Go To Evaluations Page
    Go To    ${EVALUATIONS_URL}
    Wait Until Page Contains Element    ${EVAL_AGENT_DROPDOWN}    timeout=${EXPLICIT_WAIT}

Expand Test Dataset Section
    [Documentation]    The Question/Reference answer inputs are only rendered once this
    ...                collapsible section is expanded - confirmed via a failure screenshot
    ...                showing the collapsed chevron with no fields visible.
    Click Element    ${EVAL_TEST_DATASET_HEADER}

Add Evaluation Question
    [Documentation]    Expands the Test dataset section if needed, then fills in a
    ...                question + reference answer pair and clicks Add question.
    [Arguments]    ${question}    ${reference_answer}
    ${is_visible}=    Run Keyword And Return Status    Page Should Contain Element    ${EVAL_QUESTION_INPUT}
    IF    not ${is_visible}
        Expand Test Dataset Section
    END
    Wait Until Page Contains Element    ${EVAL_QUESTION_INPUT}    timeout=${EXPLICIT_WAIT}
    Input Text      ${EVAL_QUESTION_INPUT}    ${question}
    Input Text      ${EVAL_REFERENCE_ANSWER_INPUT}    ${reference_answer}
    Click Button    ${EVAL_ADD_QUESTION_BUTTON}

Get Evaluation Question Count Text
    Wait Until Page Contains Element    ${EVAL_QUESTION_COUNT}    timeout=${EXPLICIT_WAIT}
    ${count_text}=    Get Text    ${EVAL_QUESTION_COUNT}
    RETURN    ${count_text}
