---
name: deeper
description: Deepen a task or prompt through expert practice, raw source material, specific methods and tools, and independent evidence of success. Use for /deeper or requests for a deeper version of a task without making it bigger. Produce a rewritten prompt before execution.
---

# Deeper

Turn the user's task into a more rigorous prompt while preserving its objective, deliverable, audience, and constraints. Improve the quality of the work within that scope.

Use the task supplied with the invocation. If none is supplied, use the current task in the conversation. If neither identifies a task, ask the user which task to deepen.

Before rewriting, answer these four questions with details specific to the task:

1. What would a top professional in this field do here that the user has not asked for? Name the missing judgment, check, or practice that would most improve the result. Explain why it matters. If the task already asks for it, say so instead of inventing a gap.
2. What is the rawest useful material that professional would start from? Name original records, observations, source files, measurements, or primary sources rather than summaries of them. Distinguish material available now from material that still needs to be obtained.
3. Which specific methods and tools would that professional use? Tie each method or tool to a step and the question it resolves. Choose methods suited to the task's constraints. Avoid generic instructions such as "research thoroughly" or unnecessary tool lists.
4. What evidence, independent of the assistant's or user's opinion, would show that the result is right? Name an observable check, external standard, reproducible measurement, or real-world outcome. State the success criterion and how to check it. For subjective work, name audience evidence or explicit evaluation criteria and state what they cannot establish.

Use available primary evidence when a concrete claim needs verification. Do not invent access to records, tools, standards, or results. Mark assumptions and missing evidence plainly.

Then rewrite the user's prompt to request exactly the work identified above. Include the objective, raw inputs, methods, deliverable, and success criteria. Preserve explicit limits on time, cost, access, and authorization. When deeper verification needs unavailable inputs or more resources, state that dependency instead of silently enlarging the assignment.

Return the four answers followed by a copyable rewritten prompt. Keep the answers concise enough that the user can see what changed and why. Do not execute the rewritten prompt unless the user also asked for execution.
