---
name: shape
description: Use when the user runs /shape, or brings a raw idea, request, or problem that isn't yet bounded and wants it ready for agents to build. Applies the shaping process from Shape Up to produce a pitch with a problem, appetite, solution, rabbit holes, and no-gos.
---

# Shape

Shape a raw idea the way Part 1 of Ryan Singer's [Shape Up](https://basecamp.com/shapeup) describes. Text passed with `/shape` is the raw idea. If none is given, ask for it.

Only three things change from the book:

- **The builders are agents.** The user is the shaper, and also makes the bet.
- **Appetites are smaller.** They're usually hours or days instead of two or six weeks.
- **The pitch is a file.**

Everything else follows the book. Don't add steps it doesn't have.

You help the user shape. Read the code and the existing system, sketch, and draft. The appetite, the choice of solution, and the no-gos are the user's calls, so put them to the user instead of deciding them.

## What shaped work is

- **Rough:** it leaves room for the builders. "Wireframes are too concrete" and "words are too abstract".
- **Solved:** the main elements are worked out and connected.
- **Bounded:** it has an appetite, and it says what not to do.

"A problem without a solution is unshaped work. Giving it to a team means pushing research and exploration down to the wrong level".

## 1. Set boundaries

- **Respond to the raw idea.** The default response is "Interesting. Maybe some day." Shape it only if the user wants to spend time on it now.
- **Set the appetite.** Ask how much time the user wants to spend. "Appetites start with a number and end with a design." This is fixed time, variable scope: the solution has to fit the appetite. The appetite also limits research: "Our appetite can also tell us how much research is worthwhile."
- **Narrow down the problem.** Ask *when* the user wanted this and what they were doing at the time, not just *what* they want. A request is one solution to a problem you haven't seen yet.
- **"Good" is relative.** Judge the solution against the appetite and the current situation, not against an ideal.
- **Watch out for grab-bags.** "Redesign" and "2.0" bundle many problems with no edge. Find the specific problem inside.

## 2. Find the elements

Move at the right speed. Explore several ideas quickly, and don't go into more detail than you need. Stop when you can answer:

- Where in the current system does the new thing fit?
- How do you get to it?
- What are the key components or interactions?
- Where does it take you?

Sketch with a breadboard in text:

- **Places:** where the user goes.
- **Affordances:** things the user can act on there.
- **Connection lines:** "how the affordances take the user from place to place."

When the solution is visual, describe a fat marker sketch, meaning a sketch too coarse to show detail. The elements you find are the output. They're "not deliverable yet": the builders still design and build them.

## 3. Find the risks and rabbit holes

"Walk through a use case in slow motion." Ask:

- Does this need technical work nobody has done before?
- Are we making assumptions about how the parts fit together?
- Are we assuming a design solution exists that we couldn't come up with ourselves?
- Is there a hard decision we should settle in advance?

Look for anything that could make the work "take multiple times the original appetite". The aim is risk that is thin-tailed, not fat-tailed. For each risk:

- **Patch the hole:** decide the answer now.
- **Declare it out of bounds:** add it to the no-gos.
- **Cut back:** remove parts that aren't really necessary. Mention them to the builders as nice-to-haves.

Then present the shaped concept to someone with technical expertise. That can be the user, or a reader who wasn't part of the shaping. The book's advice is to ask whether X is possible within the time, not whether X is possible at all. You're hunting for time bombs and for ways to drastically simplify.

## 4. Write the pitch

Write it so someone without the shaping context can get the idea. It has five ingredients:

1. **Problem:** "a single specific story that shows why the status quo doesn't work." This gives a baseline: the solution should make that story end better.
2. **Appetite:** "How much time we want to spend and how that constrains the solution". Write it as a fixed time the builders can check.
3. **Solution:** the elements, as a breadboard or fat marker sketch.
4. **Rabbit holes:** the risks found in step 3 and how they're patched.
5. **No-gos:** what is excluded from the concept.

Save the pitch as a file the builders can read, and show it to the user. The user decides whether to bet on it.

## After the bet

These come from later parts of the book. Pass them on to the builders with the pitch:

- **No extension by default:** "If they don't finish, by default the project doesn't get an extension." Unfinished work goes back to shaping.
- **Assign projects, not tasks.** Hand over the whole pitch. Done means deployed.
- **Get one piece done:** build "something tangible and demoable early" by "integrating vertically on one small piece of the project instead of chipping away at the horizontal layers."
- **Decide when to stop:** compare down to the baseline, not up against the ideal. Hammer scope to fit the time.
