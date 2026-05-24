---
name: Split Bash chains into separate tool calls
description: Don't combine commands with && or compound shells in one Bash call — split them into individual tool calls so each matches its own allow rule.
type: feedback
originSessionId: f17b1887-1f64-45dc-8bc8-86813d15de5f
---
When I'd naturally write `cmd1 && cmd2 && cmd3` in a single Bash call, send them as separate Bash tool calls instead. Parallel when independent (multiple Bash blocks in one message), sequential when one depends on another.

**Why:** the user's permission allowlist in `~/.claude/settings.json` matches per-command (e.g. `Bash(jq *)`). Compound commands chained with `&&` are matched against the allow rules as a single whole string, so they fail to match and trigger an unwanted permission prompt. Confirmed when a `jq ... && echo ... && echo ...` validation chain prompted despite `Bash(jq *)` being allowed.

**How to apply:** any time I'm about to chain validation, summary, or formatting steps in one Bash call (`&& echo "done"`, command substitution in echos, etc.), split. Pipes (`|`) within a single tool invocation are still fine — the issue is sequencing with `&&`/`;`/`||`, not piping. If a compound command is genuinely the right tool (e.g. requires shell-level state between steps), accept the prompt rather than adding a brittle chain-friendly allow rule.
