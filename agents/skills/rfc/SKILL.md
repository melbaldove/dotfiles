---
name: rfc
description: Use for any design work before implementation - "write an RFC", "write a design doc", "how should we approach X", "propose...", "design X", or "address the feedback on this RFC". This is the design-doc workflow; when a brainstorming skill triggers for design work, run this skill instead and do not write a separate design doc. Not for implementation plans (use the project's plan workflow after acceptance) or for recording a decision that is already settled (write the ADR directly).
---

# RFCs

## Core Rule

An RFC records one main decision, the subordinate decisions it needs, and the contracts that follow from them. It answers **what** and **why**. It does not answer **how**; the implementation plan answers that.

The reader is fluent in English. The cost to control is **cognitive load**: what the reader must hold in mind, find elsewhere, or reconstruct.

This skill owns scope, structure, and workflow. For prose and evidence, use the project's own rules first: its `AGENTS.md`, `CLAUDE.md`, or style guide. Use `writing.md` in this skill for anything the project does not define. Where the two conflict, the project's rules win.

## Document Scope

| Document | Answers | Lives in |
| --- | --- | --- |
| PRD | Why build it, for whom | Wherever the product team keeps it |
| **RFC** | What we build, which option, and the contracts between parts | See **Location and Numbering** |
| Implementation plan | How: files, tasks, tests | The same repo as the RFC, through the project's plan workflow |
| ADR | One precedent-setting decision, after acceptance | The ADR directory of the repo that owns the decision (see stage 5) |

An RFC includes decisions with their reasons, component contracts, data shapes, key flows with their failure paths, and the tests that would reject the design.

An RFC excludes logic longer than 20 lines, configuration files, infrastructure-as-code detail, runbooks, and dashboards. If you write one of these, you have moved to implementation; move it to the plan. Data shapes such as schemas and response bodies have no line limit.

## Location and Numbering

- If the project defines where RFCs live, follow it. Otherwise put the RFC in the repo that owns the change, at `docs/rfcs/NNN-slug.md`.
- Number RFCs in sequence within their directory. Never reuse or renumber a number.
- When an RFC refers to an RFC in another directory, use the relative path, not only the number.
- Keep an index in `docs/rfcs/README.md`, and create it if it is missing. Each row gives the number, title, status, and the date of the last status change.
- Status values: `Draft`, `In review`, `Accepted`, `Rejected`, `Superseded by <RFC-NNN or relative path>`. Do not delete a rejected or superseded RFC; it records why.

## Workflow

Some work is too small for an RFC: one obvious option, no precedent-setting decision, and nothing another person must approve. Judge the size after you read the evidence in stage 1. For small work, state the approach in the reply, get the user's agreement, and implement it. Write no design doc.

All other work goes through five stages. Do not skip a stage. A stage can be short.

### Stage 1: Frame

Find the evidence before you ask the user anything. Read the project's domain docs, existing RFCs and ADRs, prior investigations, and the code that the change touches.

1. Ask the questions that the evidence cannot answer, one at a time. Prefer multiple choice. Skip this step when the user supplies a completed investigation or a written brief that already holds the evidence.
2. Write the **Definition of Done**: each property the finished work must have, and the test that proves it. These tests are the acceptance tests. The pilot and the rejection criteria trace back to them. If you cannot write this table, the problem is not yet clear; return to step 1.
3. State your recommended option, and the one reason that rules out each rejected option. Get the user's agreement on the direction before stage 2.

### Stage 2: Draft

Copy `template.md` to the RFC path, fill it in, and add its row to the index. You write the draft yourself, because the evidence is in your context and a subagent would have to rebuild it.

- Keep the template's section order. Omit only the sections that the template marks as optional.
- Give every component the six contract fields of the template.
- Mark every claim that is not verified (see **Markers**).

### Stage 3: Review

Give the draft to one fresh reviewer that has not seen the drafting, so it reads as the reader will. Use a fresh subagent if your tool supports one; otherwise ask the user to start a new session. The reviewer's prompt is the text of `reviewer.md` below the `---` line, followed by:

- the RFC path,
- the paths of the evidence that the RFC cites,
- the paths of the project's rule files (`AGENTS.md`, `CLAUDE.md`, or style guide), if any,
- the constraints that bind the task, if the project has delegation rules.

The reviewer returns findings only. Handle them in this order:

1. Check each finding against the evidence. A finding is a hypothesis, not an order. A finding that you reject with evidence is closed; record the reason in your reply to the user.
2. Fix every MAJOR and MODERATE finding that you accept.
3. For each `MISSING CONTEXT` item, answer it from the evidence if you can. If you cannot, ask the user. If nobody can answer it now, add a `VERIFY` marker with an owner at the claim it affects.
4. Show MINOR findings to the user, and fix them only if the user agrees.
5. Stop when a round returns no open MAJOR or MODERATE finding, that is, none that you accept and have not fixed. Otherwise, start a new reviewer for the next round, and give it the rejected findings with their reasons. After 3 rounds, show the remaining MAJOR and MODERATE findings to the user and ask how to proceed.

### Stage 4: Feedback

When you give the RFC to other people, set its status to `In review`. Update the index row at this and every later status change.

Handle each comment separately:

1. Restate the technical concern in one sentence.
2. Check it against Current State, Definition of Done, the component Invariants, and Abandoned Ideas. If the comment proposes an option already in Abandoned Ideas, answer with the reason recorded there, unless the comment brings new evidence.
3. Accept, push back with evidence, or ask for the missing fact. Do not accept a change only to reach agreement.
4. When you accept a comment, change the RFC. When a comment shows that a recorded fact is wrong, read the source again; do not patch only the sentence.

Run stage 3 again after a substantial change. The 3-round limit starts again for that pass.

### Stage 5: Accept and Split

An RFC is ready for acceptance when all of these are true:

- The last review round has no open MAJOR or MODERATE finding, and no `MISSING CONTEXT` item that is neither answered nor converted to a `VERIFY` marker.
- No `[DECISION NEEDED]` marker remains.
- Each open `[VERIFY]` and `[INFERENCE]` marker has an owner and a phase that resolves it.

Only the person named in the `Decides:` field accepts or rejects the RFC. To reject it, set the status to `Rejected`, add a `**Rejected because:**` line under the status with the reason, and update the index. To accept it:

1. Write one ADR for each precedent-setting decision, with status `Accepted`. If the project defines ADR criteria, use them. Otherwise a decision is precedent-setting when it is hard to reverse, later work depends on it, and it was chosen over real alternatives. Put the ADR in the ADR directory (default `docs/adr/`) of the repo that owns the decision, in the project's ADR format. The ADR states the decision. Its context states the problem in one or two sentences and links to the RFC for the rest. Its alternatives link to Abandoned Ideas instead of restating them.
2. Add the ADR links to the RFC, in the section that makes each decision.
3. Set the RFC status to `Accepted`, and update the index.
4. Hand off to the project's plan workflow: one implementation plan for each phase, each linking to the RFC.

After acceptance, change the RFC only to fix errors or to mark it superseded. A new decision needs a new RFC.

## RFC Rules

The reviewer checks these rules and the prose rules (the project's, or `writing.md`).

1. **The Abstract states the decision.** A reader who stops after the Abstract knows what is proposed.
2. **One design in the Proposal.** Other options go in Abandoned Ideas, each with the evidence that ruled it out, not a story of the evaluation.
3. **Fixed skeleton.** Use the same section order, the same six contract fields, and the same marker syntax in every RFC. The reader learns the layout once and then scans.
4. **Tables for comparison, prose for reasoning.** Use a table when the reader compares items that have the same attributes. Use prose when each step depends on the one before.
5. **Define before use.** Define each component and term before you refer to it, or link to its definition in the project's docs.
6. **Visible uncertainty.** Every marker appears inline and again in Open Items. A hidden uncertainty costs more than a visible one, because the reader cannot tell which claims to trust.
7. **No length target.** Stop when the reader has what they need to decide.

## Markers

Use visible markers, not HTML comments. A reader of rendered Markdown cannot see a comment.

| Marker | Use it for | Required content |
| --- | --- | --- |
| `[VERIFY: …]` | A claim from a live system, code, or document that nobody checked for this RFC, including a claim from memory or a stale document | What to check, and how |
| `[INFERENCE: …]` | A conclusion drawn from evidence, not observed | What it was inferred from |
| `[DECISION NEEDED: …]` | A choice that belongs to someone other than the author | The options, and who decides |

Make a decision where you can, and add a `VERIFY` marker if it rests on an unchecked fact. Use `DECISION NEEDED` only when the choice belongs to someone else.

## Diagrams

- Start the Proposal with the decision, then a component diagram. Draw every other diagram that you mention; a description of a diagram is not a diagram.
- Draw in D2, as the universal Diagrams rule describes: a structure-only D2 block and its committed SVG. Use D2 shapes for components and data flow, `shape: sequence_diagram` for request paths, and states with labelled edges for lifecycles.
- Give each diagram a one-line caption that states what the reader should see in it.

## Credits

The workflow adapts ideas from `lemieux/rfc-skills` (MIT): document scope, one proposal with abandoned alternatives, a fresh reviewer that returns graded findings, and evaluating feedback against recorded constraints.
