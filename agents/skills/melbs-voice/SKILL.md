---
name: melbs-voice
description: Use when drafting or revising text that the user will send or post under their own name to colleagues, leadership, or partners, such as a Slack or chat reply, a thread post, or a short email. Not for Claude's own replies to the user, which follow the Writing Replies rules.
user-invocable: false
---

# Melbs Voice

Text written with this skill goes out under the user's name. It has to sound like the user talking to a colleague: direct, warm, sure of the work, and honest about what is not done yet. Apply the spoken-voice skill too. Where the two differ, this skill wins.

## The shape of a reply

1. Answer the question in the first sentence: "Yes.", "Yes please, but as concrete cases.", "Not yet.", or "My read: ...". Never open with thanks, praise, or a restatement of their message.
2. If you need something from them, ask for it in its exact shape. Name the parts you want back, then say in one clause what you will do with them: "For each one, one real example: what kicks it off, what it should do on its own, what it should bring to you, and what a great result looks like. I turn each of those into tests the system has to pass."
3. If they wrote a numbered list, answer with a numbered list in the same order. Give each item one or two sentences that say who does what, for example that agents do the work and people make the calls.
4. End on the idea that ties the message together, with its substance: what it does, and why it matters to the reader. Usually this is the thing the user owns and is building, named the way the user names it. A slogan, a summary of the message, or "let me know if you have questions" is not an ending. A specific invitation is: "Let me know any gaps in my understanding of the vision."

## Voice

- First person. "I" for the user's own work and "we" for the company. Own the work plainly: "I've drafted", "I'm building", "I'm still refining".
- Casual and direct. Use contractions, plain phrases like "Yes please" and "kicks it off", and an aside in parentheses when it saves a sentence ("(I've got the vision)").
- Use the reader's words, not the codebase's. Before a draft goes out, translate every internal name into the plain thing it means: a decision-log id, a law set, a branch, a ticket number, a phase code, or a term that only the user's agents use. "A standing outcome with a schedule trigger" becomes "a standing research job". Keep a name only when the reader already uses it, such as a product they know or "the kernel".
- Prefer concrete to abstract. A short list of real examples in parentheses, such as "(mail, chat, meetings, docs)", beats a category word.
- Keep the status honest. Say what already works with "can already", what is in progress with "I'm building" or "still refining", and what is missing as missing. Never present a design as built. Never give a date that no measured run supports.
- Do not quote agent-hour estimates to people outside the work, because they read them as calendar time. Say what comes next instead, or give a calendar time only when one is measured.
- One sharp contrast is allowed when it states a real decision: "a new team means new people and permissions, not new tools". Use at most one per message.

## Format

- In chat and Slack, use no headers, bold, tables, or emoji. Keep paragraphs to one to three sentences. Use a numbered list only to mirror theirs or to list what you are asking for.
- Make it as short as the answer allows. A plain reply stays under 100 words. A reply to a leader's list of questions stays under about 200.
- Inside a thread, write no greeting and no sign-off. Use no exclamation marks and no em dashes.
- In email, keep the same voice, add a one-line greeting, and sign with the name the user signs with.

## Before you hand it over

Check the draft once against each question:
1. Does the first sentence answer what they asked?
2. Is every name one that the reader already uses?
3. Is every claim about the work true today, with work in progress marked as in progress?
4. Would the user say each sentence out loud to this person?
5. If they asked in a list, does the reply mirror it?

Give the user the draft as a quote block they can paste. Outside the quote, add at most three short lines: what the draft states that you could not verify, and any choice in it that the user may want to reverse, such as an ask they did not request.

## Examples

A short synthesis, when someone asks whether the user understands a direction:

> Yes. My read: we're building our own version of the office suite (mail, chat, meetings, docs, tasks) on one shared core, where agents do the operating work and people make the judgment calls. I've drafted a design for that core, which I'm still refining. Let me know any gaps in my understanding.

A reply to a leader's numbered list. They wrote: "Could this run our hiring loop? (1) find candidates for open roles, (2) schedule and prep interviews, (3) tell us when a role's process is broken. Want me to write up more detail?"

> Yes please, but as concrete cases rather than more detail on the idea. For each of the three, one real example: what kicks it off, what it should do on its own, what it should bring to you to decide, and what a great result looks like. I turn each of those into tests the system has to pass before we trust it with that job.
>
> How it fits what I'm building:
> 1. Sourcing: a standing search for each open role that brings you a short list with the reasons for each person. You decide who gets contacted.
> 2. Scheduling and prep: agents book the slots and write the interview packs. The first message to a candidate still waits for one tap from a person.
> 3. Broken process: it watches each role's pipeline and tells you when something stalls, with what it saw.
>
> Getting it that reliable is exactly what the kernel is for. Every action any agent takes goes through it, and it checks each one against rules we've written down and proven: what the agent may do, on whose authority, within what limits, and with what evidence before anything counts as done. That's what lets us hand agents more autonomy safely.

The same reply in the voice to avoid:

> Great question! **Short answer:** yes. Here's how our architecture handles each:
> - **Sourcing** → the G5/G8 inquiry family with standing outcomes and metered effects
> - **Scheduling** → fully autonomous via standing grants
>
> Let me know if you have any questions!

It opens with praise, uses internal names the reader has never seen, claims autonomy that is not built, and ends on an empty offer.
