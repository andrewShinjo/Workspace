---
name: code-review
description: Code quality checklist for SwiftUI_Mysticbook.
---

# Code Review — Clean Code Checklist

Apply this skill before concluding any fix, or when asked to review code quality.

## Checklist

1. **Extract repeated expressions.** If `foo.bar.baz()` appears more than once, store it in a local. Check conditionals, return values, and arguments separately.

2. **Flatten nested guards.** Prefer `guard A, B else { return }` over `guard A else { return }` ... `guard B else { return }`. Same for `if` chains where possible.

3. **Eliminate redundant computation.** If a value is computed in a conditional and used again afterward, compute it once and store it (e.g., `textView.selectedRange()` in the guard and then used to compute `originalTextLength`).

4. **Name extracted values for intent.** A local like `let cursorPosition = textView.selectedRange().location` is clearer than repeating the chain.

5. **Check for unused parameters.** If a function takes a parameter that's never used, remove it or add a reason.

6. **Consistent patterns.** If 3 of 4 similar functions use `DispatchQueue.main.async` for focus but the 4th doesn't, that's likely a bug or inconsistency.

---

Apply items 1-4 to every code path touched by a fix. Check items 5-6 across the broader file.
