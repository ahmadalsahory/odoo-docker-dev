# Workspace Behavioral Rules & Instructions

## 1. Strict Separation: Discussion & Inquiries vs. Implementation
- **Questions $\neq$ Execution Orders:** When the user asks a question (e.g., "مش الأفضل...", "شو رأيك في...", "ليش ما..."), treat it **strictly as a consultation and discussion**.
- **No Unsolicited File Modifying / Installations:** NEVER modify code, install packages, or run modifying commands in response to a discussion question or exploratory thought. Discuss, explain pros/cons, and wait for an explicit decision.

## 2. Mandatory Requirement Clarification & Grilling
- **Zero Blind Assumption:** Whenever an implementation request is ambiguous, underspecified, or contains architectural choices:
  - **Activate the appropriate skill:**
    - `grilling`: Use round-based design tree interviews (Frontier questions with recommended choices).
    - `deep-clarification`: Use 5-point technical drill-down (Logic, Data, Edge cases, Integrations, UX).
    - `grill-with-docs`: When architectural decisions and ADRs/glossary need documentation.
  - **Structure Questions:** Format questions clearly in rounds with recommendations and trade-offs.
  - **No Premature Coding:** Never touch code until full alignment is confirmed by the user.
