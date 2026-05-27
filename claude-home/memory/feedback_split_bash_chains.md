---
name: One bash command per tool call (no chains, no compound scripts) — with bulk-loop and wrapper caveats
description: Default to one Bash tool call per command so each matches its own allow rule. Carve-outs apply for genuinely-bulk inner loops and for tools already wrapped via nix shell. $var splitting is about Claude-side literal substitution, not avoiding shell variables in legitimate scripts.
type: feedback
originSessionId: f17b1887-1f64-45dc-8bc8-86813d15de5f
---

When I'd naturally write `cmd1 && cmd2 && cmd3`, a `for f in ...; do ...; done` loop, or a multi-line script in a single Bash call, **default to** sending them as separate Bash tool calls. Parallel when independent (multiple Bash blocks in one message), sequential when one depends on another.

**Why:** the user's permission allowlist in `~/.claude/settings.json` matches per-command (e.g. `Bash(jq *)`, `Bash(git *)`). Claude Code's matcher has two defensive rules that block auto-approval:

1. **Compound constructs prompt.** `&&` / `;` / `||` chains, newline-separated multi-statement scripts, `for` / `while` / `if` blocks — even if each piece individually matches an allow rule, the whole thing prompts. The matcher tests the leading command token (`for`, `if`, etc.), not the bodies. Confirmed across `jq ... && echo` validation chains, `for f in ...; do head -1 "$f"; done` inspection loops, and a 22-statement `cd ... ; set -e ; git add ... ; git commit ... ; ...` commit script.
2. **Variable/command expansion prompts.** Commands containing `$f`, `$(...)`, or other simple_expansion / command_substitution nodes trigger "Contains simple_expansion" — the matcher can't statically predict the expanded form.

**Default application:**
- One git command per call (`git add X`, then `git commit -m Y` as two separate Bash tool calls).
- One inspection per call (`head -1 X`, `head -1 Y`, `head -1 Z`), or use Read instead.
- Pipes (`|`) within a single tool invocation are still fine — the issue is sequencing (`&&`/`;`/`||`/newline) and dynamic values, not piping.

**Carve-outs — don't apply the rule mechanically:**

1. **Genuinely-bulk inner loops.** A `for i in $(seq 1 548); do pdftotext -f $i -l $i ...; done` for per-page text extraction across a whole book is one bash script that prompts once. Splitting it into 548 individual tool calls is absurd — pages of transcript, hundreds of prompts (since each `pdftotext` invocation contains its own expansion of `$i`), no audit-trail benefit because nobody reads a 548-line page-by-page extraction log. **The right move:** accept the one prompt for the compound script, gated by the leading `for` / `nix shell` / whatever. Bulk-loop threshold: if the loop body is the same operation repeated N times where N > ~5 and the operations are mechanically uniform, keep the loop.

2. **`nix shell PKG --command X` already loses inner-command granularity.** Every `pdftotext` or `pdftoppm` invocation is `nix shell nixpkgs#poppler-utils --command pdftotext ...`. The matcher sees `nix shell` as the leading token, not `pdftotext`. Per-INNER-command allow rules don't apply regardless of splitting. **The right lever** to regain granularity is pre-promoting frequently-used tools into the devShell (via the user's nix config) so they're directly callable as `pdftotext ...` — splitting bash invocations doesn't help here. The user has `Bash(nix shell *)` allowed broadly; that's the gate.

3. **`$var` rule applies to Claude-side construction, not legitimate shell scripts.** When I'm building a Bash invocation from values I know, write the literal: `mv path/a path/b`, not `src=path/a; dst=path/b; mv "$src" "$dst"`. That's a visibility issue (the user can preview the literal command in the tool-use block) more than an allowlist-matching issue. Inside a legitimate shell script where `$var` is the whole point (a `for` loop's loop variable, parsing tool output, etc.), `$var` is fine — the script is one tool call, takes one prompt, runs the loop body normally.

**Net:** default to splitting, but recognize the carve-outs. The Bash tool's parallel-tool-call ability means many simple commands cost roughly the same as one compound script, BUT bulk inner loops and `nix shell`-wrapped tools are the cases where compound-prompt is actually cheaper than fan-out.
