# RFC-NNN: <Decision as a noun phrase>

**Status:** Draft
**Date:** YYYY-MM-DD
**Author:** <name>
**Decides:** <the person who accepts or rejects this RFC>
**Supersedes:** <relative path to the superseded RFC. Optional; omit the line if none.>

## Abstract

<Two or three sentences. State the decision, its main reason, and the problem it solves.>

## Definition of Done

<Each property that must be true when the work is complete, and the test that proves it. These tests are the acceptance tests.>

| Property | Test |
| --- | --- |
| | |

## Current State

<Only the facts that the decision depends on. Do not restate a context document; link to it.>

| Area | Observation (date) | Why it matters here | Evidence |
| --- | --- | --- | --- |
| | | | <link to the query, file, or method> |

## Proposal

<Start with the decision and a component diagram. Then add one subsection per component, each with the six contract fields. Put the key flows after the components.>

```d2
direction: down
source: Source
component: Component
consumer: Consumer
source -> component -> consumer
```

![<Caption>](NNN-slug-components.svg)

*<Caption: what the reader should see in this diagram.>*

### <Component name>

| Field | Content |
| --- | --- |
| Responsibility | <One sentence> |
| Inputs | <What it reads, and from where> |
| Outputs | <What it writes, where, and in what shape> |
| Invariants | <What must always be true, and what it must never do> |
| Failure and recovery | <How it fails, how a rerun behaves, and what an operator does> |
| Owner | <Repo and team> |

<Show data shapes, such as schemas, request and response bodies, and file layouts, in full. Keep logic to pseudocode of 20 lines or fewer.>

### Key Flows

<For each flow, give the normal path and then each failure path. When the flows have the same attributes, use a table with one row per case.>

## Pilot and Rejection Criteria

<The pilot is the smallest real test that could prove the design wrong. State what it covers, what it measures, and the thresholds that would reject the design. If no pilot is needed, write "No pilot:" and the reason. The rejection criteria are required either way.>

## Phases

<Ordered phases, with their dependencies and exit criteria. No calendar dates. Give an effort estimate only when the decision depends on it, and mark it as an estimate.>

## Cost

<Optional. Include this section only when cost affects the decision.>

| Item | Assumption | Range |
| --- | --- | --- |
| | | |

## Risks

<Optional. Include this section only for risks that are not small.>

| Risk | Likelihood and impact | Mitigation, or the reason to accept it |
| --- | --- | --- |
| | | |

## Abandoned Ideas

<One row per option that was seriously considered. Omit options that were never realistic.>

| Option | Ruled out because | Evidence |
| --- | --- | --- |
| | | |

## Open Items

<Every VERIFY, INFERENCE, and DECISION NEEDED marker in this RFC, listed once.>

| Marker | Owner | Resolved by (phase) |
| --- | --- | --- |
| | | |
