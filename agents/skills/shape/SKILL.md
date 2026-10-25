---
name: shape
description: Use when the user runs /shape, or brings a raw idea, request, or problem that isn't bounded yet and wants it ready for agents to build. Produces a short pitch with the problem, appetite, solution as a breadboard, rabbit holes, and no-gos.
---

# Shape

Turn a raw idea into work an agent can build in a fixed time. Text after `/shape` is the idea. If there is none, ask for it. The method is Ryan Singer's shaping, from Shape Up, with agents as the builders.

Shaped work is solved, bounded, and rough. Its main parts are worked out and connected. It has a fixed time and says what's out. It leaves the details to the builders.

The bet, the appetite, the choice between solutions, and the no-gos are the user's calls. Put each one to the user with your recommendation instead of deciding it.

## Steps

1. **Question the idea before solving it.** A request is one solution to a problem you haven't seen yet. Find the specific situation where today's system fails, and check the premise against the real system. If the work isn't worth doing now, say so.
2. **Get the appetite before designing.** Ask how much agent time the work is worth, in hours or days. The appetite is a budget, not an estimate, so never derive it from a solution you have already sketched. Design to fit it. When a solution doesn't fit, change the solution or cut scope, not the appetite.
3. **Breadboard the solution** with the `breadboard` skill, for work with or without a UI. The breadboard is the source of truth for the solution, and the pitch's prose follows its structure. When the layout itself is the problem, use a coarse sketch instead.
4. **Find the rabbit holes:** parts that could make the work take several times the appetite. Check them against the real system. Patch each one with a decision, declare it out of bounds, or cut the part.
5. **Write the pitch** to a file and show it to the user. It has five parts: problem, appetite, solution, rabbit holes, and no-gos.

## When to stop

Stop when a builder could start without asking about the problem, the main parts, or the risky decisions. Leave names, formats, schemas, file layouts, and exact rules to the builders, unless one of them is a rabbit hole. Spend shaping time in proportion to the appetite: a pitch for a few hours of work fits on one page.
