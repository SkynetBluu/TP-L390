---
name: Code blocks reproduced verbatim from source
description: For book-distillation work (RTA_Skill, skillset/, AoE references), code snippets in output files must be verbatim from the source — no paraphrasing — with narrow carve-outs.
type: feedback
originSessionId: 4c478b28-5b3c-49a0-b97e-c74e5d961f60
---
When extracting from a book into reference / skill notes (RTA_Skill, skillset/, references/), code snippets in the output must be reproduced verbatim from the source.

- **Verbatim** = operators, constants, loop structure, order of operations all preserved.
- **Variable renaming** is OK for clarity (e.g., `x` → `input`, `y` → `output`) but must be consistent across the snippet and must not change semantics.
- **Comments** may be added, rewritten in your own words, or dropped.
- **Bracketing** changes (e.g., adding `()` for clarity) are fine only when they don't alter precedence.
- **License-restricted sources** (Numerical Recipes) — skip the code entirely and describe the algorithm in prose.
- **If the source's code isn't substantively different from a generic C idiom** after the audio-themed wrapper is stripped — omit it rather than fabricate book-like code.
- **Confirmed book typos in RTA_Skill extracts: use the corrected form**, don't propagate the typo. Flag the discrepancy as a spot-check candidate. (This differs from the skillset/ layer, where workflow.md §5.4 prescribes verbatim-with-`[sic]` notes — RTA_Skill is downstream of skillset/ and uses the corrected form.) Example: K&R p. 108 prints `void swap(void *v[], int i, int j;)` with a stray semicolon in the parameter list; the RTA_Skill extract omits the semicolon.

**Why:** Paraphrased code in a reference layer creates silent bugs — subtle changes (operator order, sign, postfix vs prefix, `==` vs `=`) look authoritative once written down and propagate downstream. The reference layer earns trust only if it's a faithful restatement of what the book actually printed. This rule already existed in `workflow.md` §5.3 ("Code fidelity") for the skillset/ layer; it was lost when RTA_Skill was scaffolded and code blocks were marked "illustrative C, not lifted verbatim."

**How to apply:** Whenever writing — or directing subagents to write — code blocks during book-distillation work, the instruction must explicitly say *"Code blocks reproduced verbatim from source — preserve operators, constants, loop structure. Variable renaming OK if consistent. Comments may be rewritten. Skip code (prose-only) for license-restricted sources."* Applies equally to inline code snippets in extract files and to topic files that aggregate from them.
