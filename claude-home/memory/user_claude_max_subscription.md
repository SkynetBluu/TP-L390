---
name: User has Claude Max subscription
description: Nimbus is on Claude Max — OAuth login covers Anthropic-side agent tools, no separate API key needed for most cases.
type: user
originSessionId: 320645da-a37f-4ef6-885b-e466dc777dfc
---
Nimbus has a Claude Max subscription. The subscription does NOT include an
Anthropic API key (console.anthropic.com is a separate product), but it DOES
authenticate OAuth-supporting agent CLIs.

How to apply:
- When suggesting auth setup for Anthropic-compatible agents (Claude Code,
  caveman-code, anything supporting `/login`), default to OAuth via the Max
  subscription. Only suggest API key path if there's a real reason (e.g.,
  needing a separate account for automation isolation, or the tool doesn't
  support OAuth).
- The OAuth dance in a headless sandbox session (no DISPLAY) means copying
  the URL into Brave on nimbus's graphical session by hand. Mention this.
- Don't recommend `ANTHROPIC_API_KEY` env-var setup as the default for
  Anthropic tools without checking if OAuth is an option first.
