---
description: Mandatory strict requirement clarification and assumption prevention rule
always_on: true
---

# Strict Clarification & Intent Rule

1. **Inquiries $\neq$ Execution:**
   - Any exploratory question or thought from the user must be answered as a **discussion only**.
   - Do NOT run modifying tools, install skills/packages, or edit code unless the user explicitly requests an action.

2. **Ambiguous Implementation Requests:**
   - When given a task to execute that is underspecified, choose and activate the relevant skill:
     - `grilling`: For design-tree interviews across open architectural decisions.
     - `deep-clarification`: For deep Odoo/backend domain and edge-case probing.
     - `grill-with-docs`: When the project requires documenting ADRs as decisions are made.
   - Formulate structured question rounds and wait for user decisions before modifying files.
