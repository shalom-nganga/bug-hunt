*** Settings ***
Documentation     Single entry point resource. Test suites import ONLY this file, not the
...               individual page resources - keeps suite-level imports clean.
Resource          config.resource
Resource          pages/login_page.resource
Resource          pages/register_page.resource
Resource          pages/chat_page.resource
Resource          pages/dashboard_page.resource
Resource          pages/agent_page.resource
