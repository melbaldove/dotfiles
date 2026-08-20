---
name: grounded-explanation
description: Use when explaining anything to someone who does not yet understand it - "what is X", "how does this work", "make me understand this", "walk me through it", "teach me", teaching a concept, a domain term, an incident, a design decision, or a codebase. Covers both a one-pass answer during work and a layered teaching session with comprehension checks. Also use it to review an explanation you already drafted. It carries a dedicated section for technical systems and code. Not for generating documentation artifacts.
---

# Grounded Explanation

## Core Rule

An explanation transfers understanding. It is not a summary of what you learned. Those two jobs pull in opposite directions: a summary compresses toward the writer's finished model, and an explanation expands toward the reader's starting one.

So write from the reader's position, not from yours. Every rule below exists because you cannot feel that position directly. Once you understand something, your fluency is indistinguishable from the subject being simple, and no amount of care corrects for it. The rules are therefore mechanical checks on the draft. Do not replace one with a judgement call.

## Before You Write

Three questions. They change the shape of the whole answer.

1. **What is the reader trying to do?** Understand a mechanism, look up a fact, or complete a task. These want different answers, and mixing them produces prose that serves none of the three.
2. **What does the reader already hold?** Use evidence from this conversation, not a guess from their seniority. This is the floor you build from.
3. **What will they do next?** Stop where their real task resumes.

## Two Registers

The same principles run in two modes, and picking the wrong one fails in opposite directions.

**Learning.** The reader has set work aside to understand something. Teach in layers, and make the comprehension check blocking: explain a layer, ask one question, wait for the answer before the next layer. Advancing without a check is lecturing.

**Working.** The reader hit something unfamiliar in the middle of a task and needs it cleared. Deliver the whole explanation in one pass and close with the specific question you expect. A quiz here obstructs the work they asked about.

When it is unclear which one you are in, ask. It is one line, and the two answers look nothing alike.

The register also bounds the recursion in principle 1. Learning descends as far as it needs to. Working descends two levels at most: past that, name the prerequisite you hit, say it is a longer explanation, and offer it — an unbounded descent into fundamentals is obstruction when someone is mid-task.

## Principles

These apply to any subject.

**1. Descend to the reader's floor, then build back up.** This is the core move, and it is recursive. Three parts, and skipping any one of them breaks it.

- **Descend.** Take the thing to explain. Does it rest on something the reader does not hold? If so, that prerequisite becomes the thing to explain, and you ask the same question of it. Repeat.
- **Stop at the floor.** The base case is the first thing the reader has already demonstrated they hold — in this conversation, in this repo, in work you watched them do. That is the bottom. Going below it is not thoroughness.
- **Come back up.** Return along the path you descended, connecting each layer to the one under it, and finish on the question they actually asked. A descent with no return leaves a pile of definitions and no assembled model, which is a worse outcome than the original confusion.

The floor is **found, not assumed**. Do not start from absolute basics as a safe default — for a reader who has the fundamentals, that buries the new part under things they already know. That is a failure, not a courtesy.

**2. When they do not follow, descend one more level — do not rephrase.** Their confusion is evidence that you misjudged the floor. Rephrasing restates the same idea at the same altitude and fails the same way twice. Recursion is the repair, and the reply is what tells you to run it again.

**3. Concrete instance before the abstraction.** A rule is something the reader must instantiate before they can use it. Give them the instance first, then name the pattern it belongs to. Where you can, let them see the thing work before you explain why it works. A small diagram or a worked trace often does this faster than another paragraph.

**4. One new idea at a time, and never before you name it.** Read the draft in order. The first appearance of every term must be its introduction. A definition arriving two paragraphs late has already cost the reader those paragraphs.

When a term you must use is itself unexplained, run principle 1 on the term: stop the main line, say you are stopping, descend on that term to the reader's floor, build back up, then return to exactly where you left off. Say that you are returning, too. An interrupt the reader can see is cheap. A term they carry unexplained for three paragraphs is not.

**5. Mark whose words they are.** Quoted from the source, your paraphrase, or a label you coined. Say which. An invented phrase reads exactly like established vocabulary, and the reader will go looking for it and find nothing.

**6. Say when you do not know what they know.** Ask, or state the assumption in one clause and continue. Both beat guessing. Silence about the assumption is the only wrong answer.

**7. Calibrate down as well as up.** Support that helps a reader who lacks context actively slows one who has it. Cut any explanation of something they have already used correctly in this conversation. Bloat is a failure mode, not a safe default.

**8. If you use an analogy, say where it breaks.** An analogy carries over entailments the reader cannot see you did not intend. Naming the boundary costs one sentence and prevents a wrong model that is harder to remove than ignorance.

**9. End at the failure mode.** Understanding a mechanism includes knowing how it breaks: what happens when the condition is not met, and what the reader would actually see. A rule with no failure attached is not yet usable.

**10. Seek evidence you were understood.** Understanding is built between two people, not delivered. Close with the specific question you expect next, or name the part you think is least clear. "Let me know if you have questions" seeks nothing.

## When They Respond

The reply is data about your explanation, not only about the reader.

- **A partly right answer is a gap, not a pass.** Never wave it through as close enough. Name the difference, close it, and only then continue.
- **Confusion means go back a layer.** You started above their floor. Descend; do not repeat.
- **A correct answer means speed up.** Drop the scaffolding for that layer and take bigger steps. Continuing at the same pace is the expertise reversal failure, arriving late.
- **A question you did not anticipate means your model of their floor was wrong.** Fix the model before answering, or the next three answers miss too.

Adapt to what the reply reveals about the kind of gap:

- A self-taught reader usually holds the practice and lacks the theory. Explain why the pattern exists, not what the code does.
- A reader new to the domain needs the concrete case before any abstraction.
- A reader expert elsewhere needs only what differs here from what they already know.

## For Technical Systems and Code

Everything above still applies. These are the additional rules for the case where the subject is a system the reader can open.

**Snippet beside the claim, link beside the snippet.** Paste the three to eight lines that carry the point, next to the point. Then add the link that best fits the available source:

- If the code is cloned, use an absolute local file link with a line number. This link opens the file in the workspace sidebar.
- If the code is not cloned, use a GitHub permalink pinned to a commit SHA or tag, with a line range.
- If the exact revision is material to the claim, use a SHA-pinned GitHub permalink even when the code is cloned. A historical comparison, release audit, or drift claim usually needs this link.

```
[lib/manifest.sh](/absolute/workspace/repo/lib/manifest.sh:32)
[lib/manifest.sh at 0203df14](https://github.com/org/repo/blob/0203df14/lib/manifest.sh#L32-L34)
```

The link is for going deeper. It is never a substitute for the lines. Making the reader follow a link to see the proof of your sentence puts the work on the wrong side.

**Never name an identifier without showing it.** A function, variable, file, flag, or table used in prose gets one of three treatments on first use: show it, link it, or say the label is yours. There is no fourth option, and no exception for names that feel self-explanatory to you.

**Give the trigger, not only the rule.** "A component with a `lambda_runtime` dependency is a lambda" is the rule. The line `lambda_http = { workspace = true }` in a named, linked `Cargo.toml` is the trigger. Show the trigger.

**Describe the mechanism, not the name.** "It uses a cache" says less than the path a request takes through it. Name the parts the reader's question actually turns on.

**Reproduce commands with their real output.** If a claim rests on behaviour, run it and paste what came back, exactly. An observed exit code settles what a paragraph of reasoning cannot.

**Say when you could not verify something.** A failed fetch, an unreadable file, a permission error: report it in the answer. An unverified claim presented at the same confidence as a verified one is the most expensive thing you can write, because it is invisible.

## Scan the Draft Before Sending

Read the draft against this list. It catches what introspection cannot.

- Is the register right — one pass for work, layers with a blocking check for learning?
- Does it start from something the reader already holds, on evidence rather than assumption?
- Every descent: does it come back up and land on the question they asked?
- Is every term introduced at its first appearance?
- Is every invented label marked as yours?
- Is there a concrete instance beside every abstraction?
- Is anything explained that the reader already used correctly? Cut it.
- Is the failure mode there?
- Does it end with a specific question rather than an open offer?

For code, additionally:

- Every backticked identifier: shown, linked, or attributed on first use?
- Every cloned source link: an absolute local file link with a line number?
- Every uncloned or revision-sensitive source link: pinned to a SHA or tag, with a line range?
- Every "X does Y": verifiable from what is on the page?
- Every claim you could not check: marked as unchecked?

## Red Flags

Each means stop and rewrite, not soften.

- "as you know", "obviously", "simply", "just" — all four assume the answer to question 2.
- A shorthand of your own invention formatted to look like source syntax.
- A function or variable named in prose with no body shown anywhere.
- A summary of code you read and the reader did not, with no quote.
- An analogy with no stated boundary.
- An explanation longer than the thing it explains, containing no example.
- A tool call that failed, silently dropped from the answer.
- A rhetorical question dressed as a comprehension check.
- In the learning register: a new layer started before the last one was confirmed, or a partly right answer accepted as close enough.
- Starting from absolute basics because it felt safer than finding the floor.
- A descent that never returns: a stack of definitions, and the original question left unanswered.
- Rephrasing a paragraph the reader already said they did not follow.

## Why These Rules

Each answers a measured failure, not a style preference.

- **The mechanical checks** answer the curse of knowledge (Camerer, Loewenstein and Weber, 1989). Hinds (1999) found experts badly underestimate how hard a task is for a novice, and that telling them about the bias did not fix it. Checks work where self-assessment does not.
- **Snippet beside the claim** answers the split-attention effect in cognitive load theory. Two sources the reader must integrate across a gap cost more than one integrated source.
- **Concrete before abstract, and the trigger** answer the worked example effect (Sweller and Cooper, 1985): studying an instance beats deriving from a rule.
- **Calibrate down** answers the expertise reversal effect (Kalyuga and colleagues): the same support that helps a novice becomes redundant load for an expert.
- **Land on known ground, and seek evidence** answer grounding in communication (Clark and Brennan, 1991). Mutual understanding is built by exchanging evidence, and the speaker's job is to lower the reader's effort rather than their own.
- **Question 1** is the Diátaxis question (Procida). **Question 3 and the failure mode** come from minimalism in technical documentation (Carroll, 1990), which anchors instruction in a real task and treats error recovery as part of understanding.
