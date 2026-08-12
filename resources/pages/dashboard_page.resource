*** Settings ***
Documentation     Page object for signed-in dashboard areas: /dashboard, /guardrails,
...               /evaluations, /statistics.
Library           SeleniumLibrary
Resource          ../config.resource


*** Variables ***
${DASHBOARD_LOADED_INDICATOR}    xpath://*[contains(text(), "Reporting agents")]
${GUARDRAILS_NAV_LINK}           xpath://a[contains(@href, "/guardrails")]
${SIDEBAR_GUARDRAILS_LINK}       xpath://nav//*[contains(text(), "Guardrails")] | //aside//*[contains(text(), "Guardrails")]
# --- Confirmed via live DOM inspection: 25 rows, columns PLACE/AGENT/DESCRIPTION/TYPE/
# TOTAL COUNT/UPDATED, standard thead+tbody structure ---
${STATISTICS_TABLE}              css:table.min-w-full.text-left.text-sm
${STATISTICS_ROW}                css:table.min-w-full.text-left.text-sm tbody tr
${PROFILE_TRIGGER}               css:div.flex.items-center.gap-3.px-3.pt-2
${LOGOUT_LINK}                   css:a[href="/logout"]


*** Keywords ***
Go To Dashboard
    Go To    ${DASHBOARD_URL}
    Wait Until Page Contains Element    ${DASHBOARD_LOADED_INDICATOR}    timeout=${EXPLICIT_WAIT}

Guardrails Nav Link Should Not Be Visible
    [Documentation]    QA guide: Guardrails nav must only render for admins.
    ...                CONFIRMED LIVE via screenshot: sidebar shows Overview, Evaluations,
    ...                Statistics, Known Places only - no Guardrails link present.
    Go To Dashboard
    Page Should Not Contain Element    ${GUARDRAILS_NAV_LINK}
    Page Should Not Contain Element    ${SIDEBAR_GUARDRAILS_LINK}

Direct Navigation To Guardrails Should Be Blocked
    [Documentation]    QA guide: non-admins cannot reach /guardrails via direct URL.
    ...                CONFIRMED LIVE: app redirects back to /dashboard rather than showing
    ...                an access-denied message.
    Go To    ${GUARDRAILS_URL}
    Wait Until Keyword Succeeds    ${EXPLICIT_WAIT}    1s    Location Should Contain Dashboard

Location Should Contain Dashboard
    [Documentation]    Helper for Wait Until Keyword Succeeds - confirms redirect to dashboard.
    ${current}=    Get Location
    Should Contain    ${current}    /dashboard

Go To Statistics Page
    Go To    ${STATISTICS_URL}
    Wait Until Page Contains Element    ${STATISTICS_TABLE}    timeout=${EXPLICIT_WAIT}

Get Statistics Row Count
    Go To Statistics Page
    ${count}=    Get Element Count    ${STATISTICS_ROW}
    RETURN    ${count}

Statistics Table Should Not Contain
    [Documentation]    Used to verify sanitization - e.g. a stored description should NOT
    ...                contain a raw phone number or email that was in the original report.
    [Arguments]    ${forbidden_text}
    Go To Statistics Page
    ${table_text}=    Get Text    ${STATISTICS_TABLE}
    Should Not Contain    ${table_text}    ${forbidden_text}

Open Profile Menu
    Click Element    ${PROFILE_TRIGGER}
    Wait Until Page Contains Element    ${LOGOUT_LINK}    timeout=${EXPLICIT_WAIT}

Log Out
    Open Profile Menu
    Click Element    ${LOGOUT_LINK}
    Wait Until Keyword Succeeds    ${EXPLICIT_WAIT}    1s    Location Should Not Contain Dashboard

Location Should Not Contain Dashboard
    ${current}=    Get Location
    Should Not Contain    ${current}    /dashboard
