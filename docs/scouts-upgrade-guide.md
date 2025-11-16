# Scouts Site Upgrade Guide (Draft)

> Goal: Bring the Scouts Hugo site to parity with the Ping Pong site: updated Hugo binary and FixIt theme, cleaner maintenance model, safe rollback.

---
## 1. Current Environment Snapshot

| Aspect | Scouts (Assumed) | Ping Pong (Reference) |
|--------|------------------|------------------------|
| Hugo versions | Side-by-side: older + newer (verify) | Side-by-side: PATH has 0.125.x; manual 0.145 extended used |
| Theme | FixIt (unknown modifications) | FixIt v0.3.12 cloned directly (no module import yet) |
| Module usage | Possibly manual theme copy | Attempted modules, fell back to clone |
| Event filtering | N/A | Implemented custom filtering partial |
| Nightly build | Unknown | GitHub workflow triggers Netlify hook |
| Encryption partial | Working? | Stubbed empty partial to bypass xxhash need |

Action: Confirm actual Scouts versions before proceeding.

---
## 2. Pre-Flight Checklist
1. Ensure working backups / access to hosting control panel.
2. Confirm production branch name (usually `main`).
3. Make sure you can build locally without error using current Hugo.
4. Tag current state: `git tag scouts-pre-upgrade` (from clean working tree).

---
## 3. Determine If Theme Has Local Modifications

### 3.1 Identify Upstream Baseline
- Find the upstream FixIt version originally used (look for `theme.toml` in theme directory or commit history).
- Download same tag in a temp folder:
  ```powershell
  $Temp = "$env:TEMP\fixit-upstream"
  if (Test-Path $Temp) { Remove-Item -Recurse -Force $Temp }
  git clone https://github.com/hugo-fixit/FixIt $Temp --branch v0.3.12 --depth 1
  ```
  (Adjust `v0.3.12` to match Scouts’ version.)

### 3.2 Diff Theme
Assuming Scouts theme path: `site/themes/FixIt/`.
```powershell
# From repo root
$DiffReport = "theme-diff.txt"
Compare-Object -ReferenceObject (Get-ChildItem $Temp -Recurse | Select-Object FullName) -DifferenceObject (Get-ChildItem .\site\themes\FixIt -Recurse | Select-Object FullName) | Out-File $DiffReport
# Alternatively use git diff if upstream tag known:
# git diff <original-tag> -- site/themes/FixIt > theme-diff.patch
```

### 3.3 Classify Changes
- Cosmetic (logo, CSS tweaks) → Extract into an override layer.
- Structural (layout changes, partial logic edits) → Move into `layouts/` outside theme (override mechanism).
- JavaScript or asset changes → Place modified assets under `assets/` or `static/`.

### 3.4 Externalize Local Modifications
1. Restore original theme directory to a pristine clone.
2. Move all custom changes into project-level override paths:
   - Layout overrides: `site/layouts/<same relative path>`
   - Asset overrides: `site/assets/...`
   - Static overrides: `site/static/...`
3. Remove accidental `.git` directories inside theme (submodule noise).

### 3.5 Validate “Pure” Theme
- Run a clean build:
  ```powershell
  hugo version
  hugo --gc --minify
  ```
- Confirm no missing partial errors.
- Visually check key pages.
- If stable, proceed.

---
## 4. Align Hugo and FixIt Versions

### 4.1 Decide Upgrade Targets
- Hugo: Use latest Extended stable (>= theme min_version + recommended for encryption + wasm support). Example: `0.146+`.
- FixIt theme: Use latest tag (e.g. `v0.3.12` or newer at time of upgrade).

### 4.2 Acquire New Hugo
- Side-by-side install (do not remove old yet).
- Verify path:
  ```powershell
  "New Hugo:"; C:\Path\To\New\hugo.exe version
  ```

### 4.3 Switch Build to New Binary
- Temporary alias function (PowerShell profile):
  ```powershell
  function hugo146 { & "C:\Full\Path\To\hugo.exe" @Args }
  hugo146 version
  ```

### 4.4 Update Theme
Option A (Clone):
```powershell
cd site/themes
Remove-Item -Recurse -Force FixIt-old  # if backing up
Rename-Item FixIt FixIt-backup
git clone https://github.com/hugo-fixit/FixIt FixIt --branch v0.3.12 --depth 1
```

Option B (Modules – Recommended Long-Term):
1. Create / restore `site/config/_default/module.toml`:
   ```toml
   [module]
     [module.hugoVersion]
       extended = true
       min = "0.146.0"  # adjust after confirming

   [[module.imports]]
     path = "github.com/hugo-fixit/FixIt"
   ```
2. Ensure `go.mod` exists at project root or inside `site/` (consistent with current structure).
3. Run:
   ```powershell
   cd site
   hugo mod get -u github.com/hugo-fixit/FixIt@v0.3.12
   hugo mod vendor   # optional for deployment stability
   ```

### 4.5 Clean Up Temporary Stubs
- Remove any stub partial like `partials/plugin/fixit-encryptor.html` if upstream works with new Hugo.

### 4.6 Full Production Build Test
```powershell
cd site
hugo --gc --minify --panicOnWarning
```
- Inspect `public/`.
- Confirm events, nav, images.

### 4.7 Commit & PR
```powershell
git checkout -b upgrade/fixit-hugo
git add .
git commit -m "Upgrade Hugo and FixIt; externalize custom overrides"
git push -u origin upgrade/fixit-hugo
```
Open PR; include diff summary.

---
## 5. Rollback Strategy
| Trigger | Action |
|---------|--------|
| Build fails | Checkout tag `scouts-pre-upgrade`; redeploy artifacts. |
| Theme regression | Restore `FixIt-backup/` directory; revert commit. |
| Performance issues | Re-run with old Hugo binary; confirm environment variables unchanged. |

Quick rollback commands:
```powershell
git checkout scouts-pre-upgrade
# If needed: restore previous deployed /public snapshot
```

---
## 6. Validation Checklist
- [ ] New Hugo version matches expectation.
- [ ] Theme min_version satisfied.
- [ ] No stub partials left.
- [ ] Overrides isolated (no direct edits inside `themes/FixIt`).
- [ ] Production build passes with `--panicOnWarning`.
- [ ] Tag created post-upgrade (`scouts-post-upgrade`).

---
## 7. Risk & Mitigation
| Risk | Mitigation |
|------|------------|
| Hidden local theme edits lost | Diff & externalize before replacing. |
| Build differences due to new Hugo features | Use staging branch & smoke test. |
| CDN / caching stale assets | Force cache bust by versioning assets or enabling fingerprinting. |
| Time pressure on rollback | Pre-tag + documented commands reduce confusion. |

---
## 8. Suggested Future Improvements (After Upgrade)
- Adopt Hugo Modules fully; remove cloned theme approach.
- Add CI step to run `hugo --gc --minify --panicOnWarning`.
- JSON feed for events for external consumption.
- Add visual regression screenshot diff (optional).

---
## 9. Frequently Asked Questions
**Q: Why not upgrade theme first?**
A: Confirm purity ensures no local edits get overwritten unexpectedly.

**Q: Why keep old Hugo for a while?**
A: Immediate rollback option if a subtle rendering regression surfaces.

**Q: When to remove the old binary?**
A: After 1–2 successful production cycles and no regressions.

---
*Draft generated: Initial version. Adapt details to actual Scouts repository structure after verification.*
