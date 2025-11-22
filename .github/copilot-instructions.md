# Copilot Project Instructions – Ping Pong Site

> Purpose: Give AI assistants clear, repeatable guidance for working in this Hugo + FixIt environment (and other Hugo sites) with minimal user friction.

---
## 1. General Hugo Best Practices

### Server & Terminal Hygiene
- Prefer ONE running `hugo server` instance. Before starting a new one, stop the previous (Ctrl+C) or reuse its terminal.
- Use background mode only when you explicitly need the terminal free for sequential commands (e.g. diffing, git ops). On Windows PowerShell you can simulate that by starting the server in a separate dedicated terminal labeled clearly.
- Avoid spawning multiple terminals with repeated `hugo server` calls. This causes sluggishness and confusion.

### Observing Output Yourself
- Inspect generated files under `public/` rather than asking the user what they see. Examples:
  - `public/events/index.html` to verify event filtering.
  - `public/index.html` for layout block issues.
- For content logic, also glance at `content/` markdown front matter to confirm params before debugging.

### Communicating Blocking States
- If you start `hugo server`, explicitly state whether you now wait for a Ctrl+C (user action) or you will continue in parallel. Example: *"Server started; I’ll inspect generated HTML without needing you to stop it yet."*
- NEVER silently wait. If an operation is blocking, announce it.

### Directory Awareness
- Root repo: `pingpong-site/`
- Hugo project: `pingpong-site/site/`
- Run Hugo commands from inside `site/` unless intentionally working with repository-level files (e.g. `.github/`, `docs/`).
- Avoid accidental nested project creation (e.g. `site/site/`). Confirm `hugo.toml` location before commands.

### Change Verification Loop
1. Make minimal template/content edit.
2. Let Hugo auto-rebuild (Fast Render Mode note). If uncertain, run with `--disableFastRender`.
3. Inspect specific affected file in `public/`.
4. Only then ask user for UX/visual confirmation if needed.

### Debugging Templates
- Use temporary, **visible** debug markers (`<p>DBG: variable={{ .Title }}</p>`) rather than Hugo comments. Remove them before committing.
- Capture dates and page counts early: `{{ len .Pages }}` / formatted time strings.

### Working With Dates
- Normalize date comparisons using a common format: `now.Format "2006-01-02"` and `dateFormat "2006-01-02" .Params.end`.
- Prefer building a filtered slice before rendering; clarity beats one giant inline conditional.

### Theme vs Module
- If cloning a theme directly into `themes/<ThemeName>`, ensure no nested `.git` remains to avoid submodule warnings.
- If using Hugo Modules, maintain `config/_default/module.toml` and rely on `go.mod`. Pin versions with `module.imports` entries.
- Always validate the theme’s `min_version` field in `theme.toml` against your Hugo binary.

---
## 2. Project-Specific Notes (Ping Pong Site)

### FixIt Adoption Attempts
We attempted three approaches:
1. **Direct module import** using `module.toml` + `theme = "github.com/hugo-fixit/FixIt"`.
   - Blockers: extra xxhash-related encryption partial expectations; instability under our older Hugo 0.145; noisy rebuild errors.
2. **Vendor / `hugo mod vendor`** strategy (abandoned early) to freeze dependencies.
   - Did not complete because module resolution friction overshadowed initial site setup goals.
3. **Direct clone of FixIt v0.3.12** into `site/themes/FixIt/` (chosen).
   - Benefit: Immediate control, easier patching (added empty `partials/plugin/fixit-encryptor.html` stub), fewer surprises.

### Why The Module Pattern Failed Short-Term
- Partial referencing wasm hashing required either newer Hugo or additional assets; Minimal reproduction easier with a stub.
- Time pressure + nested repo mistakes made iteration slower.
- Multiple terminals and path confusion (ran from repo root instead of `site/`) amplified complexity.

### Long-Term Recommendation
- Upgrade Hugo to a version >= the theme’s future `min_version` (e.g. >= 0.146+ if needed).
- Remove stub `fixit-encryptor.html` once upstream functionality works.
- Re-enable Hugo Modules using a clean `module.toml` to simplify updating (`hugo mod get -u`).
- Keep the theme uncluttered: no debug markers, delete unused demo content.

### Event Filtering Implementation
- Logic lives in `layouts/partials/events/list.html` + wrapper in `layouts/events/list.html`.
- Filtering contract: include pages where `end >= today` and `active != false`.
- Edge Cases Considered: events ending today, single-day events with same start/end, past events hidden.

### Branching / Review
- Feature branch: `feature/initial-site-setup` → PR → review → merge → nightly Netlify build workflow triggers.
- Keep future changes small: separate branch for “Upgrade Hugo & revert to modules”.

---
## 3. Suggested Additional Sections For Hugo Projects

### Deployment Checklist
- Confirm Hugo binary version (run `hugo version`).
- Verify theme `min_version` compatibility.
- Run a production build: `hugo --gc --minify` (in a controlled environment).
- Scan `public/` for leftover debug artifacts.

### Performance Quick Wins
- Minify assets (FixIt already helps).
- Prune unused images or demo content.
- Avoid huge date/time loops in templates; precompute slices.

### Testing Strategy
- Smoke test: build site and confirm events page count.
- Add a small script (optional) to parse `public/events/index.html` and assert future events present.

### Rollback Strategy (Theme Upgrades)
1. Tag current commit (e.g., `git tag site-stable-initial`).
2. Save `public/` snapshot if needed.
3. Upgrade theme or Hugo.
4. If failure occurs, checkout tag and redeploy.

---
## 4. Interaction Guidelines For Assistants
- Proactively read files rather than ask user to paste snippets.
- Announce intent before batch operations ("Staging edits to create upgrade guide").
- Keep responses concise unless user requests detail; use bullet lists.
- Avoid restating full unchanged plans—report only deltas.

---
## 5. Common Mistakes To Avoid
| Mistake | Mitigation |
|---------|------------|
| Running Hugo from wrong directory | Check for `hugo.toml` before starting server. |
| Multiple server terminals | Kill prior terminal or reuse window. |
| Asking user for obvious build output | Inspect `public/` directly. |
| Leaving debug markup in production | Remove before commit. |
| Theme submodule conflicts | Delete nested `.git` inside theme directory. |

---
## 6. Future Enhancements
- Convert event filtering to custom output (JSON) for potential frontend integration.
- Add automated date rollover test in CI.
- Reintroduce modules once Hugo upgraded.
- Document a lightweight script to sync theme with upstream tag changes.

---
## 7. Quick Reference Commands (Windows PowerShell)
```powershell
# Start server (foreground)
C:\Path\To\hugo.exe server -D

# Start server with full rebuild focus
C:\Path\To\hugo.exe server -D --disableFastRender

# Production build
C:\Path\To\hugo.exe --gc --minify

# Kill all terminals (VS Code Command Palette)
# workbench.action.terminal.killAll
```

---
*Last updated: INIT VERSION*
