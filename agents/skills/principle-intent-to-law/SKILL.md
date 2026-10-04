---
name: principle-intent-to-law
description: Apply before implementing or reviewing behavior with correctness obligations, especially authority, state transitions, persistence, or formal verification. Turn intent into an adequate machine-checkable contract before choosing the implementation.
---

# Intent to law

Establish what must hold before deciding how to implement it. Express the user's intent as a specification that the implementation cannot redefine to make itself pass.

**Why:** A checked proof establishes its stated proposition under its premises. It does not establish that the proposition captures the user's intent. Correct code for an inadequate specification is still the wrong product.

**The pattern:**

- **Trace obligations to intent.** Identify the relevant inputs, permitted results, forbidden results, and state changes. Each obligation names its source. Specify outcomes and required boundaries without prescribing an unnecessary algorithm or model strategy.
- **Choose the appropriate contract.** Use the repository's existing specification and verification tools. Encode valid states in types and express critical, tractable properties as quantified laws with checked proofs where supported. Elsewhere, use executable specifications, assertions, property checks, and tests. Describe their coverage as tested, not proved. If formal proof is required, a missing proof remains a gap. Do not change the language or add a proof tool merely to follow this principle.
- **Challenge the specification before implementation.** Construct the simplest wrong implementation that would satisfy it. Try returning nothing, refusing all work, discarding data, ignoring identity, and using stale state where relevant. Check that premises admit intended inputs and that specification predicates do not just repeat the implementation's decisions. Sorting needs preservation of each element's multiplicity as well as ordered output.
- **Cover permitted behavior and progress.** Refusal laws alone admit a system that does nothing. State when valid work must be accepted and what result it must produce. If intent requires eventual progress, specify the transitions and assumptions about scheduling, delivery, failures, and resources. A terminating pure function does not prove that a daemon eventually finishes its work.
- **Make assumptions explicit.** Name the facts supplied by callers, storage, clocks, external services, and host effects. Identify the trusted checker, translation, compiler, runtime, and foreign code relevant to the claim. A proof about a model does not automatically establish the behavior of these components.
- **Check the implementation against the contract.** Run the required checker on the actual definitions and their dependencies. Reject unresolved proof holes and prohibited unsafe dependencies. For changed rules, use allowed and refused examples, and mutations in both directions where practical, to expose weak laws. Count a mutation only when it falsifies the required property, not merely when it breaks a particular proof term. Distinguish counterexamples, proof rejection, checker crashes, and timeouts. A crash or timeout establishes neither truth nor falsity. These controls do not replace a universal proof.
- **Bind the contract to execution.** Trace the running path to the checked decision and its committed result. Test bypasses, input mappings, and host assumptions at their boundaries. Use installed and live evidence for effects and semantic judgment that the formal model does not cover.
- **Preserve the target.** Repair the implementation or proof when a check fails. Do not weaken a law, alter an oracle, or hide a failed case to obtain a pass. A legitimate contract change must trace to changed intent and follow the repository's review and approval rules.

Scale the artifact to the change. A local obligation may fit beside an existing type or test. A change to authority or durable state needs an explicit specification and assumption record. For behavior-preserving changes, retain the contract and rerun its relevant checks. Do not invent a new law or verification workflow. When a repository supplies an intent-to-law or law-review skill, use it for the local mechanics.

**The test:** Can an implementation satisfy the specification and still violate the stated intent? If so, strengthen the specification or name the uncovered obligation. Separately assess how much of the specification the evidence establishes. Finite tests can miss defects even when the specification is adequate. Report what is proved, what is tested, and what remains assumed or unobserved.
