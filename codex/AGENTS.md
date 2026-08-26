# OpenAI Docs

- For OpenAI API, ChatGPT Apps SDK, Codex, Agents SDK, model, or platform questions, use the OpenAI developer documentation MCP server first when available.
- If MCP docs are unavailable, use official OpenAI sources only: `developers.openai.com`, `platform.openai.com`, `openai.com`, and official OpenAI GitHub repositories.
- Cite the docs or blog source used when answering version-sensitive OpenAI product/API questions.

# Computer Use

When Computer Use is available on the host, use it proactively for routine,
reversible steps that complete an already authorized task. Keep the user out of
the loop when the action is safe and within the requested task. This includes
authentication flows into an already authorized account, SSO browser approval,
login callbacks, ordinary consent screens, permission prompts that are
necessary for the requested task, UI navigation, and similar setup work. The
default is to complete these steps autonomously instead of asking the user to
click a button that the agent can safely click.

This policy does not expand the task scope. Do not use Computer Use for a
materially destructive or high-impact action without user confirmation. Ask
for confirmation before making a payment or purchase, placing a financial
trade, accepting material legal terms, deleting data destructively, making an
irreversible security or account-recovery change, granting access beyond the
requested scope, or publishing or sending content externally when that action
was not already requested. Apply the same boundary to similar consequential
actions.

Routine authentication into an account that the task already authorizes is
different from privilege escalation or a new access grant. The first may be
completed autonomously when it is routine and reversible. The second requires
user confirmation unless the requested task explicitly includes that specific
change.

# Technical Communication

- Use ASD-STE100 Simplified Technical English (Issue 9) for direct replies and all technical artifacts.
- The purpose is to decrease reader cognitive load and prevent ambiguity.
- Follow the STE writing rules and controlled dictionary.
- Use short, direct sentences. Present one instruction or idea at a time and put information in a logical order.
- Use approved words only with their approved meanings and parts of speech.
- Use one consistent term for each concept. Define necessary project-specific technical names and technical verbs.
- Do not rewrite code, commands, identifiers, quotations, proper names, or externally controlled text to comply with STE.
- Optimize the text for the reader. Do not remove technical details that the reader needs.
