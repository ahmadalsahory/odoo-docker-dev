---
name: deep-clarification
description: A rigorous framework for thoroughly decomposing user requests, uncovering hidden assumptions, analyzing edge cases, and conducting structured probing through clarifying questions to ensure 100% precision before implementation.
---

# Deep Clarification & Requirement Probing Skill

This skill provides a systematic, zero-assumption workflow for dissecting user requests, uncovering ambiguities, and drilling down into every technical and architectural detail through interactive inquiry.

---

## Core Philosophy: Zero Blind Assumption
- **Never guess** missing requirements, field types, business logic flows, or architectural trade-offs.
- A well-asked question saves hours of refactoring and rework.
- Drill down until the scope, data model, behaviors, and edge cases are crystal clear.

---

## Probing Dimensions (The 5-Point Drill-Down)

Whenever analyzing a request, inspect these 5 dimensions for gaps or ambiguities:

### 1. Functional & Business Logic
- What is the exact triggering event?
- What are the required validations, state transitions, and access permissions?
- What should happen in abnormal/failure paths?

### 2. Data Model & Architecture
- Which models, tables, or fields are affected or created?
- What are the relationships (1:M, M:M, constraints, ondelete behaviors)?
- Are there dependencies on existing Odoo Enterprise/Community modules?

### 3. Edge Cases & Boundary Conditions
- What happens with empty/null inputs, large datasets, or concurrent actions?
- Are there multi-company, multi-currency, or multi-language considerations?

### 4. Integration & Environment
- How does this interact with Docker, `odoo.conf`, or external APIs?
- Are there database migrations or upgrade script requirements?

### 5. UI/UX & User Interaction
- Where should buttons, views, menus, or reports appear?
- Is there a specific view type required (form, tree/list, kanban, wizard)?

---

## Questioning Protocol (How to Ask the User)

When ambiguities are found:

1. **Be Concise & Structured:** Group related questions logically. Do not overwhelm with disorganized text.
2. **Offer Clear Options & Trade-offs:** When multiple valid solutions exist, present them as choices with pros and cons (e.g., Option A vs Option B).
3. **Recommend a Default:** State your recommended approach while asking for the user's preference.
4. **Pause Execution:** **STOP** calling modification tools or writing code until the user answers.
