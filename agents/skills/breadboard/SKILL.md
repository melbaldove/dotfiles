---
name: breadboard
description: Use when the user runs /breadboard, or when shaping or understanding a system needs its parts and wiring laid out as places, affordances, and connections. Works for systems with or without a UI, existing or proposed.
---

# Breadboard

A breadboard shows what a system lets its driver do and where each action leads. Like an electronics breadboard, it has all the components and wiring but no casing: no visual design and no implementation detail.

- **Driver:** whoever acts on the system: a person in a UI, a person at a command line, an agent, or another program. Name the driver.
- **Places:** where the driver can be, such as a screen, a command, an endpoint, a running job, or a state.
- **Affordances:** what the driver can act on or see at a place.
- **Connections:** where each affordance takes the driver, and what it changes.

There are two uses:

- **Map an existing system.** Read the real system, and back each place and connection with evidence. Report anything the map shows that the user didn't expect.
- **Design a new one.** Leave out names, schemas, and types, the way an electronics breadboard leaves out the casing.

The breadboard is the source of truth. Prose, plans, and slices that describe the same system follow its structure, and change when it changes.
