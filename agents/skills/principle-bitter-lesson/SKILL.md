---
name: principle-bitter-lesson
description: Apply when designing agent capabilities, routing, tools, validation, or fixes for misunderstood requests. Prefer general model reasoning and feedback over task-specific semantic rules.
---

# The Bitter Lesson

[Richard Sutton's The Bitter Lesson](https://www.cs.utexas.edu/~eunsol/courses/data/bitter_lesson.pdf), dated March 13, 2019, argues for general methods that scale with computation, especially search and learning.

Apply that lesson to agent engineering as follows.

Give the model the tools, context, and execution time needed to complete the authorized goal. Let it interpret requests and choose actions. Return useful tool results so it can investigate, correct mistakes, and continue.

Before adding a rule, identify what the rule must enforce. Use deterministic code for machine contracts, authorization, credential protection, resource limits, and execution reliability. Use model judgment for meaning, intent, and choice of approach.

When the model fails, inspect its instructions, available tools, observations, and feedback before adding special cases. Prefer a general capability improvement over another task-specific workflow. Remove semantic rules that duplicate or contradict model reasoning.

Keep real constraints enforceable. A model's interpretation does not grant permission or prove an external identity. Let it gather evidence through tools, then enforce access and API contracts at execution.

Evaluate outcomes across varied requests, languages, and contexts. Include cases beyond the failure that prompted the change. Passing a test that repeats one example does not establish general capability.
