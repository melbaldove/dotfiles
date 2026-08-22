---
name: building-core-loop-first
description: Use when planning or implementing a product, feature, subsystem, or integration whose main journey does not yet work through the real entry point, especially when horizontal or architecture-first delivery could delay user-visible proof.
---

# Build the Core Loop First

Comprehensive specification and core-loop-first delivery are compatible. Design the whole intended system when the task requires it. Build and verify it as ordered vertical slices.

## Core Loop Discovery

If the request or specification does not identify a clear core loop, use brainstorming to establish it before finalizing the specification or implementation plan.

Identify:

- The primary user.
- The action they take through the real entry point.
- The valuable result they can observe.
- The central product property that must be real for the result to count.

Express it as:

> Given [user context], when [user action], then [observable value].

If multiple journeys could be central, present them with their trade-offs and ask the user to select one.

Core-loop discovery is a required output of brainstorming. It does not limit the breadth or detail of the comprehensive specification.

## Specification Contract

A comprehensive specification can define the complete product: requirements, architecture, components, contracts, data, failure modes, security, operations, migration, and future behavior. Do not omit known requirements or useful design detail merely because they are outside the first implementation slice.

The specification must also:

- Separate target design, verified current behavior, and unproven assumptions.
- Name the core user journey and its observable value.
- Identify the first vertical slice through the proposed design.
- Map later requirements into an ordered implementation sequence.
- State which architectural decisions are required now and which remain revisable until evidence arrives.

Specification breadth does not authorize implementation breadth.

## First Implementation Slice

Express its acceptance boundary as:

> Given [real user context], when the user [acts through the real entry point], then the user can observe [valuable result].

Use one scenario and one central product claim. Use the fewest behaviors needed to prove it. Include the safety and authorization needed to run this path responsibly.

For implementation:

1. Run the current path and record what already works.
2. Write one acceptance check for that journey at the public boundary.
3. Build the smallest real path that makes it pass.
4. Demonstrate the result through the real interface.
5. Compare the result with the comprehensive specification. Update assumptions and continue with the next planned vertical slice.

## Proof Standard

Start at the interface the user will use. Reach each layer needed for the result. Use real components and integrations where safe and practical. Produce evidence the user can inspect.

An internal call, test-only interface, mock, fallback, or skipped core property does not prove the journey. If continuity is central, include a dependent later turn or a restart.

If an external dependency is costly, unsafe, or unavailable, name the unproven boundary and add the smallest separate live check. Do not claim full verification.

## Implementation-Order Rule

Every implementation task scheduled before the first proof must answer:

> Which step of the current user journey requires this now?

If there is no direct answer, keep it in the specification and schedule it for a later slice. Do not build it before the first proof. Necessary setup is allowed. Prefer existing concrete paths where they satisfy the design.

The implementation plan may cover the full specification. Organize it by demonstrable vertical outcomes, not by horizontal layers such as “build all storage,” “build all APIs,” then “add the UI.” Architecture can be designed in advance; its implementation enters the current slice only when that slice requires it.

## Common Rationalizations

| Rationalization | Correction |
|---|---|
| "A complete specification means we should build every foundation first." | Specification order and implementation order are different. |
| "We cannot specify later slices until the first one works." | Specify known requirements now; mark assumptions and revise them with evidence. |
| "The demo comes after the architecture." | Implement the architecture needed by the core journey and prove it first. |
| "We will need these components later." | Keep them in the design. Build them when their vertical slice requires them. |
| "The tests pass." | Run the real entry point. Internal tests do not prove user access. |

## Completion Check

Before expanding scope, all answers must be yes:

- Can the user perform the core action through the real interface and observe the value?
- Does the evidence cover the central product property?
- Did implementation defer work this journey does not need, without deleting it from the approved specification?
- Did we demonstrate the result, not only internal parts?

If any answer is no, continue the current slice.
