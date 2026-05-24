---
name: Self-hosted Forgejo instance
description: Nimbus runs a Forgejo (git host) on LAN. Claude has an account there and can push via HTTP basic auth using a token in ~/.netrc.
type: reference
originSessionId: a8d20c7f-2d77-4016-8805-fe4985de1ec2
---
- URL: `http://192.168.1.3:3030/` (LAN-only, plain HTTP — fine on this network).
- Forgejo username for claude: **`clawed`** (note spelling — not `claude`).
- Auth: HTTP basic via `~/.netrc` (mode 0600). Format:
  ```
  machine 192.168.1.3
  login clawed
  password <personal access token>
  ```
- Verify: `curl -sS --netrc http://192.168.1.3:3030/api/v1/user` returns JSON with `"login":"clawed"`.

**How to apply:** When pushing a project repo, use `http://192.168.1.3:3030/<owner>/<repo>.git` as the remote URL. Git picks up `.netrc` automatically — no extra `credential.helper` setup needed.

**Not yet wired:** `git user.name` / `user.email` for commit authorship. If pushing, also need `git config --global user.name ...` and `user.email ...` to match the Forgejo account (or use per-repo config). Token regeneration: log into Forgejo as clawed → User Settings → Applications.
