---
name: fixer
description: Debugging methodology for SwiftUI_Mysticbook.
---

# fixer — Bug Analysis

Apply this skill when fixing bugs.

## Methodology: Trace Before Theorize

1. **Find the entry point.** Read the relevant source files end-to-end for the feature area involved.
2. **List every conditional** along the code path. For each, write down the **exact concrete values** from the bug report scenario — not generic values, the actual values at that point.
3. **Generalize the input space.** For each conditional, enumerate the full set of possible input values or states. Consider orthogonal variables that aren't checked by any conditional but should be.
4. **Only after tracing every conditional and its full state space**, draw conclusions. Do not invent theories about event ordering, timing, or system behavior before this step.
