---
name: spoken-voice
description: Write and revise prose so it sounds like a person talking rather than a machine performing. Use when drafting or editing any prose - documentation, READMEs, PR descriptions, essays, emails, user-facing copy, release notes, comments longer than a line. Strips the rhetorical tics that mark generated text.
---

# Spoken Voice

Prose written under this skill has to survive being read out loud. If a sentence would sound like a keynote when spoken to one person sitting across a table, rewrite it.

The rules below constrain the prose you produce. They do not constrain this document, which uses lists and labels because it is reference material.

## Banned rhetorical moves

| Move | What it sounds like | Do instead |
|---|---|---|
| Antithesis | "This isn't a refactor, it's a rewrite." | Say the true thing. "This is a rewrite." |
| Corrective negation | "The problem was never speed. The problem was memory." | "Memory was the problem." |
| Negative parallelism | "No config. No build step. No lock-in." | Pick the one that matters and put it in a sentence. |
| Negative anaphora | "Not for beginners. Not for teams. Not for prototypes." | Same fix. One clause, stated plainly. |
| Contrasting pairs | "Less ceremony, more shipping." | Drop the frame and describe the ceremony you removed. |
| Rule of three | "It's fast, cheap, and reliable." | Use two items, or four, or one. Triads read as rehearsed. |
| Setup and payoff | A sentence whose only job is making the next sentence land. | Cut the setup and keep the sentence with content in it. |
| Landing sentence | A short punchy closer at the end of a section. "That's the whole trick." | End on the last real point and stop there. |
| Paragraph pinning | Closing a paragraph with a short declarative that restates its thesis. | Let the paragraph end on its last piece of information. |
| Summary beat | A sentence restating what the reader just read. | Delete it. The reader was there. |
| Parallel structure inside a paragraph | Consecutive sentences built on the same frame. | Change the shape of each one: different openings, different clause order. |
| Throat clearing | "It's worth noting that", "At its core", "In practice", "Let's dig in." | Start with the sentence you were going to write second. |

## Rhythm

No em dashes. Use a comma, a period, or a rewrite, and parentheses when nothing else fits.

No parataxis. Stacked short independent clauses ("It ran. It failed. We looked.") perform style instead of carrying meaning, so subordinate some of them into longer sentences.

Vary sentence length unpredictably. Avoid the steady medium pulse, and avoid the long-sentence-then-very-short-sentence pattern, which is setup and payoff with a stopwatch. Two sentences of similar length back to back is fine and often right, because speech does that.

Read the draft aloud. Wherever you would naturally rephrase while speaking, rephrase in the text.

## Diction

- No stacked noun phrases. "User authentication flow migration timeline" becomes "when we move the login flow."
- No filler intensifiers: genuinely, really, truly, actually, simply, quite, very, incredibly.
- No corporate-register verbs: leverage, underscore, reflect, enable, facilitate, drive, unlock, surface, showcase, highlight. Plain verbs work. "Use", "show", "means".
- No nominalization. "Made the decision to" becomes "decided". "The implementation of caching" becomes "caching". "Provides support for" becomes "supports".
- No hedging qualifiers: arguably, somewhat, relatively, fairly, perhaps, it seems, tends to, may well. State the claim, or state your uncertainty as a fact you know ("I tested two of the four cases").
- No performed enthusiasm. Skip "great question", "excited to", and words like beautiful or elegant used as applause. Skip exclamation points.

## Revision pass

Draft first, then go through the draft once per check. Trying to satisfy everything while writing produces stilted output.

1. Search for every dash character and rewrite each sentence containing one.
2. Read only the last sentence of each paragraph. Cut it if it restates the paragraph or lands a beat.
3. Read only the first sentence of each paragraph. Cut it if it warms up instead of saying something.
4. Find every sentence with "not" or "isn't" near a comma, then check whether it is antithesis or corrective negation.
5. Count the items in every in-sentence list of qualities. When the count is three, change it.
6. Look for two sentences in a paragraph that share a shape, then rewrite one.
7. Scan for the banned words listed above.
8. Read the whole thing aloud.

## What good output looks like

Before:

> It's worth noting that this isn't just a performance fix. At its core, the change reduces allocation, improves cache locality, and cuts latency. Simple, fast, and safe. That's the whole point.

After:

> The change cuts allocations in the hot loop, which brought p99 latency from 40ms down to about 12ms on the staging box. Cache behavior probably helps too, though I did not measure that separately.

The second version says more while performing less, and it hands the reader a number they can check.
