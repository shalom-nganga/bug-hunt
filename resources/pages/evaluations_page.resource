*** Settings ***
Documentation     Page object for /evaluations - runs RAG quality checks against an agent's
...                test dataset. Locators based on visible placeholder/button text from
...                screenshot - not yet confirmed via DevTools element inspection.
Library           SeleniumLibrary
Resource          ../config.resource


*** Variables ***
${EVAL_AGENT_DROPDOWN}       css:select
${EVAL_RUN_BUTTON}           xpath://button[contains(., "Run evaluation")]
${EVAL_QUESTION_INPUT}       css:textarea[placeholder*="Question" i], input[placeholder*="Question" i]
${EVAL_REFERENCE_ANSWER_INPUT}    css:textarea[placeholder*="Reference" i], input[placeholder*="Reference" i]
${EVAL_ADD_QUESTION_BUTTON}  xpath://button[contains(., "Add question")]
${EVAL_QUESTION_COUNT}       xpath://*[contains(text(), "of 50 questions")]
${EVAL_EMPTY_STATE}          xpath://*[contains(text(), "Add questions and run the first evaluation")]


*** Keywords ***
Go To Evaluations Page
    Go To    ${EVALUATIONS_URL}
    Wait Until Page Contains Element    ${EVAL_AGENT_DROPDOWN}    timeout=${EXPLICIT_WAIT}

Add Evaluation Question
    [Documentation]    Fills in a question + reference answer pair and clicks Add question.
    ...                Does NOT run the evaluation - separate keyword for that.
    [Arguments]    ${question}    ${reference_answer}
    Input Text      ${EVAL_QUESTION_INPUT}    ${question}
    Input Text      ${EVAL_REFERENCE_ANSWER_INPUT}    ${reference_answer}
    Click Button    ${EVAL_ADD_QUESTION_BUTTON}

Get Evaluation Question Count Text
    Wait Until Page Contains Element    ${EVAL_QUESTION_COUNT}    timeout=${EXPLICIT_WAIT}
    ${count_text}=    Get Text    ${EVAL_QUESTION_COUNT}
    RETURN    ${count_text}
