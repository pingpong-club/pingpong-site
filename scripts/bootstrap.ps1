# Windows PowerShell bootstrap for the Ping Pong Club site
$ErrorActionPreference = 'Stop'

# Config (change if you like)
$BRANCH = $env:BRANCH; if ([string]::IsNullOrWhiteSpace($BRANCH)) { $BRANCH = 'scaffold' }
$FIXIT_VERSION = $env:FIXIT_VERSION; if ([string]::IsNullOrWhiteSpace($FIXIT_VERSION)) { $FIXIT_VERSION = 'latest' }
$BASE_BRANCH = $env:BASE_BRANCH; if ([string]::IsNullOrWhiteSpace($BASE_BRANCH)) { $BASE_BRANCH = 'main' }

function Ensure-Dir($path) {
  if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
}

function Write-File($path, [string]$content) {
  $dir = Split-Path -Parent $path
  if ($dir) { Ensure-Dir $dir }
  $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($path, $content, $Utf8NoBom)
}

# Prereqs
if (-not (Get-Command hugo -ErrorAction SilentlyContinue)) {
  Write-Host "Error: Hugo not found. Install Hugo Extended: https://gohugo.io/getting-started/installing/" -ForegroundColor Red
  exit 1
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host "Error: Git not found. Install Git for Windows: https://git-scm.com/download/win" -ForegroundColor Red
  exit 1
}

# Create directories
"Creating directories..."
Ensure-Dir ".github/workflows"
@(
  "site/config/_default",
  "site/archetypes",
  "site/content/events",
  "site/layouts/partials/events",
  "site/layouts/events",
  "site/assets/js",
  "site/static",
  "specs"
) | ForEach-Object { Ensure-Dir $_ }

# Files
$README = @'
# CCHS Ping Pong Club Website

This repository hosts the Hugo site for the Concord–Carlisle High School Ping Pong Club. It uses the FixIt theme via Hugo Modules (vendored for reproducible builds) and deploys on Netlify.

## Layout

- `site/` — Hugo project root (content, layouts, assets, config).
- `specs/` — Specs, decisions, and operations docs.
- `netlify.toml` — Netlify build config (builds from the `site/` subdirectory).

## Local development

Prereqs:
- Hugo Extended (install from https://gohugo.io)
- Git

Clone and run:
```bash
git clone https://github.com/pingpong-club/pingpong-site.git
cd pingpong-site/site

# One-time modules init + vendoring (creates a committed snapshot under _vendor/)
hugo mod init github.com/pingpong-club/pingpong-site
hugo mod get github.com/hugo-fixit/FixIt@latest  # or pin a specific tag
hugo mod vendor

hugo server -D
```

Your site will be available at http://localhost:1313.

Note: Do not edit files under `_vendor`. Place overrides in `site/layouts/...`.

## FixIt theme integration (Modules + vendor)

We import FixIt as a Hugo Module (see `site/config/_default/module.toml`), then vendor the dependency so the full theme is available in the repo under `site/_vendor/...`. Commit `_vendor` along with `go.mod` and `go.sum`.

To update FixIt later:
```bash
cd site
hugo mod get github.com/hugo-fixit/FixIt@vX.Y.Z
hugo mod vendor
git add _vendor go.mod go.sum
git commit -m "chore: update FixIt to vX.Y.Z"
```

## Netlify deployment

- Netlify-managed builds via the Netlify GitHub App.
- `netlify.toml` sets `base = "site"`, so Netlify builds from the Hugo subdirectory.
- Defaults:
  - Build command: `hugo --minify`
  - Publish directory: `public`
  - Environment: `HUGO_VERSION` set

Steps:
1. Install/configure the Netlify GitHub App for the pingpong-club org and grant access to this repo.
2. In Netlify, "Add new site" → "Import from Git" → select the repo → accept the default build settings.

## Nightly rebuild (expire past events automatically)

We filter events at build time in Hugo. To ensure past events drop off without commits, a scheduled GitHub Actions workflow calls a Netlify Build Hook nightly.

Setup:
1. In Netlify, Site settings → Build & deploy → Build hooks → Add build hook (e.g., “nightly-rebuild”). Copy the URL.
2. In GitHub repo, Settings → Secrets and variables → Actions → New repository secret:
   - Name: `NETLIFY_BUILD_HOOK_URL`
   - Value: the build hook URL from step 1.
3. The included workflow `.github/workflows/nightly-rebuild.yml` will run nightly and trigger a deploy.

## Specs

See:
- `specs/0001-initial-setup.md` for Cloudflare/Netlify/GitHub checklist
- `specs/REPO_STRUCTURE.md` for structure notes
'#
Write-File "README.md" $README

$NETLIFY = @'
[build]
  base = "site"
  command = "hugo --minify"
  publish = "public"

[build.environment]
  HUGO_VERSION = "0.134.3"
  HUGO_ENV = "production"
  HUGO_ENABLEGITINFO = "true"

[context.deploy-preview]
  command = "hugo --minify -b $DEPLOY_PRIME_URL"
'@
Write-File "netlify.toml" $NETLIFY

$GITIGNORE = @'
# OS/editor
.DS_Store
Thumbs.db
.idea/
.vscode/

# Hugo artifacts (keep _vendor, ignore others)
site/public/
site/resources/
site/.hugo_build.lock

# Node (if added later)
node_modules/
'@
Write-File ".gitignore" $GITIGNORE

$WF = @'
name: Nightly Netlify Rebuild

on:
  workflow_dispatch:
  schedule:
    - cron: "15 7 * * *"

jobs:
  trigger:
    runs-on: ubuntu-latest
    steps:
      - name: Check secret
        run: |
          if [ -z "${{ secrets.NETLIFY_BUILD_HOOK_URL }}" ]; then
            echo "NETLIFY_BUILD_HOOK_URL is not set. Add it in GitHub > Settings > Secrets and variables > Actions."
            exit 1
          fi
      - name: Call Netlify build hook
        run: |
          curl -sS -X POST "${{ secrets.NETLIFY_BUILD_HOOK_URL }}"
'@
Write-File ".github/workflows/nightly-rebuild.yml" $WF

$MODULE = @'
[module]
  [module.hugoVersion]
    extended = true
    min = "0.120.0"

  [[module.imports]]
    path = "github.com/hugo-fixit/FixIt"
'@
Write-File "site/config/_default/module.toml" $MODULE

$HUGO_CFG = @'
baseURL = "https://pingpongclub.org/"
title = "CCHS Ping Pong Club"
languageCode = "en-us"
enableRobotsTXT = true

[outputs]
  home = ["HTML", "RSS"]

[permalinks]
  events = "/events/:slug/"

[menu]
  [[menu.main]]
    name = "Home"
    url = "/"
    weight = 10
  [[menu.main]]
    name = "Events"
    url = "/events/"
    weight = 20
'@
Write-File "site/config/_default/hugo.toml" $HUGO_CFG

$PARAMS = @'
# FixIt parameters; customize as needed.
[params]
  version = "1.0.0"

[params.site]
  title = "CCHS Ping Pong Club"

# Footer customization is done by overriding the partial in layouts/partials/footer.html
'@
Write-File "site/config/_default/params.toml" $PARAMS

$ARCH = @'
---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
start: {{ .Date.Format "2006-01-02" }}
end: {{ .Date.Format "2006-01-02" }}
location: ""
active: true
draft: false
---
'@
Write-File "site/archetypes/event.md" $ARCH

$EVENT_INDEX = @'
---
title: "Events"
description: "Club events and meetups"
---
'@
Write-File "site/content/events/_index.md" $EVENT_INDEX

$EVENT_SAMPLE = @'
---
title: "Fall Tournament"
start: 2025-11-20
end: 2025-11-20
location: "Gym A"
active: true
---
Bring your paddles!
'@
Write-File "site/content/events/sample-event.md" $EVENT_SAMPLE

$EVENT_LIST = @'
{{ define "main" }}
<main class="container">
  <h1>{{ .Title }}</h1>
  {{ partial "events/list" . }}
</main>
{{ end }}
'@
Write-File "site/layouts/events/list.html" $EVENT_LIST

$EVENT_PARTIAL = @'
{{/* Build-time filtering for upcoming events */}}
{{ $now := now }}
{{ $candidates := where (where site.RegularPages "Type" "events") ".Params.active" "!=" false }}

{{ $upcoming := slice }}
{{ range $candidates }}
  {{ $endStr := .Params.end | default .Params.start }}
  {{ with $endStr }}
    {{ $end := time . }}
    {{ if ge $end $now }}
      {{ $upcoming = $upcoming | append .Page }}
    {{ end }}
  {{ end }}
{{ end }}

{{ $sorted := sort $upcoming ".Params.start" }}

<ul class="events">
  {{ range $sorted }}
    <li class="event-item">
      <a href="{{ .RelPermalink }}">{{ .Title }}</a>
      {{ with .Params.start }} <time datetime="{{ . }}">{{ . }}</time>{{ end }}
      {{ with .Params.end }} – <time datetime="{{ . }}">{{ . }}</time>{{ end }}
      {{ with .Params.location }} — {{ . }}{{ end }}
    </li>
  {{ else }}
    <li>No upcoming events.</li>
  {{ end }}
</ul>
'@
Write-File "site/layouts/partials/events/list.html" $EVENT_PARTIAL

$FOOTER = @'
<footer class="site-footer">
  <div class="container">
    <div class="left">
      © {{ now.Year }} Concord–Carlisle Ping Pong Club
    </div>
    <div class="right">
      <a href="/">Home</a> · <a href="/events/">Events</a>
    </div>
  </div>
</footer>
'@
Write-File "site/layouts/partials/footer.html" $FOOTER

$STRUCTURE = @'
# Repository structure

```
.
├── netlify.toml                  # Netlify config: build from site/ and publish site/public
├── README.md                     # Project overview and setup
├── specs/                        # Specs, decisions, ops docs
│   ├── REPO_STRUCTURE.md         # This document
│   └── 0001-initial-setup.md     # Initial Cloudflare/Netlify/GitHub checklist
└── site/                         # Hugo project root
    ├── archetypes/
    │   └── event.md              # Event content archetype
    ├── assets/                   # Custom JS/CSS (optional)
    ├── config/
    │   └── _default/
    │       ├── hugo.toml         # Base Hugo config
    │       ├── params.toml       # Theme/site params (FixIt)
    │       └── module.toml       # Hugo Modules import of FixIt
    ├── content/
    │   └── events/
    │       ├── _index.md         # Events list page
    │       └── sample-event.md   # Example event content
    ├── layouts/
    │   ├── events/
    │   │   └── list.html         # Section list template (uses partial)
    │   └── partials/
    │       ├── events/
    │       │   └── list.html     # Build-time filter for upcoming events
    │       └── footer.html       # Example FixIt override (custom footer)
    ├── static/                   # Static files (images, downloads, etc.)
    ├── _vendor/                  # Vendored modules (commit after running `hugo mod vendor`)
    └── resources/                # Hugo build cache (do NOT commit)
```

Notes
- Hugo lives entirely in `site/`. Netlify builds from that subdirectory.
- We import FixIt via Hugo Modules and then vendor it into `site/_vendor/` for reproducible builds and easy browsing in VS Code.
- Do NOT edit files in `_vendor`. Override theme templates/partials under `site/layouts/...`.
- `specs/` is for project docs, decisions, and operational handoff notes.
'@
Write-File "specs/REPO_STRUCTURE.md" $STRUCTURE

$CHECKLIST = @'
# 0001 — Initial setup checklist

Cloudflare
- [ ] Sign up (owner: andygett@bullseyeconsulting.com)
- [ ] Register `pingpongclub.org`
- [ ] Update nameservers at registrar to Cloudflare
- [ ] Email Routing: enable and add route(s)
  - [ ] `webmaster@pingpongclub.org` → `ag@bec.com`
- [ ] Publish "receive-only" anti-spoofing DNS
  - [ ] SPF (TXT @): `v=spf1 -all`
  - [ ] DMARC (TXT _dmarc): `v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s`
  - [ ] (Optional later) DMARC reporting `rua=mailto:dmarc@pingpongclub.org`

GitHub
- [ ] Create organization: `pingpong-club`
- [ ] Create repository: `pingpong-site` (Private)
- [ ] Require 2FA for org members
- [ ] Create team(s), invite members as needed

Netlify
- [ ] Create team (Free/Starter initially)
- [ ] Connect repo via Netlify GitHub App (Netlify-managed builds)
- [ ] Build command: `hugo --minify`
- [ ] Publish dir: `public`
- [ ] Set `HUGO_VERSION` env var

Hugo + Theme
- [ ] Initialize modules: `hugo mod init github.com/pingpong-club/pingpong-site`
- [ ] Add FixIt: `hugo mod get github.com/hugo-fixit/FixIt@vX.Y.Z`
- [ ] Vendor: `hugo mod vendor`
- [ ] Commit `_vendor`, `go.mod`, `go.sum`
- [ ] Implement events filtering (Hugo build-time approach included)

Handoff
- [ ] Document how to transfer Netlify site or invite new admins
- [ ] Cloudflare Members: add/remove admins as leadership changes
'@
Write-File "specs/0001-initial-setup.md" $CHECKLIST

# Optional summarized transcript placeholder
$SUMMARY = @'
# Chat transcript — 2025-11-15 (summary)

Summary of decisions and steps captured. Request a full verbatim transcript if needed; it will be lengthy and can be added later.

- Hugo + FixIt via Hugo Modules with vendored snapshot
- site/ subdirectory for Hugo; specs/ for docs
- Netlify-managed builds (GitHub App), base=site, command=hugo --minify, publish=public
- Cloudflare DNS + Email Routing (receive-only); SPF: v=spf1 -all, DMARC: p=reject
- Events filtered at build time; nightly GitHub Action calls Netlify Build Hook
- Ownership: GitHub org (pingpong-club), private repo; Netlify Free seat considerations
'@
Write-File "specs/chat-transcript-2025-11-15.md" $SUMMARY

# Hugo module init and vendoring
Write-Host "Initializing Hugo modules and vendoring FixIt ($FIXIT_VERSION)..."
Push-Location "site"
if (-not (Test-Path "go.mod")) {
  & hugo mod init github.com/pingpong-club/pingpong-site | Out-Null
}
& hugo mod get "github.com/hugo-fixit/FixIt@$FIXIT_VERSION"
& hugo mod vendor
Pop-Location

# Git commit and push
if (-not (Test-Path ".git")) {
  Write-Host "Error: .git not found. Run this inside your cloned repository." -ForegroundColor Red
  exit 1
}

# Create/switch branch
$branchExists = (git branch --list $BRANCH) -ne $null -and (git branch --list $BRANCH).Trim() -ne ''
if ($branchExists) {
  git checkout $BRANCH | Out-Null
} else {
  git checkout -b $BRANCH | Out-Null
}

git add .
try { git commit -m "feat: initial Hugo scaffold (FixIt modules, Netlify config, specs, nightly rebuild) and vendored theme" | Out-Null } catch {}

# Push
try { git push -u origin $BRANCH } catch {}

# Create PR if gh is available
if (Get-Command gh -ErrorAction SilentlyContinue) {
  gh pr create --title "Scaffold Hugo site (FixIt, Netlify, specs, nightly rebuild)" `
    --body "Initial scaffold: site/ Hugo project, FixIt via modules + vendored snapshot, Netlify build config, events filtering, specs docs, and nightly rebuild workflow. After merge, connect Netlify and add NETLIFY_BUILD_HOOK_URL repo secret to enable the nightly deploy." `
    --base $BASE_BRANCH --head $BRANCH
} else {
  Write-Host "GitHub CLI (gh) not found. Open a PR in the GitHub UI: compare '$BRANCH' into '$BASE_BRANCH'." -ForegroundColor Yellow
}

Write-Host "Done. Next steps:" -ForegroundColor Green
Write-Host "1) Open/confirm the PR from branch '$BRANCH' to '$BASE_BRANCH' (your son can review/merge)." -ForegroundColor Green
Write-Host "2) In Netlify: create a Build Hook and add NETLIFY_BUILD_HOOK_URL secret in GitHub to enable the nightly workflow." -ForegroundColor Green
Write-Host "3) Connect the repo in Netlify (builds from site/ with hugo --minify)." -ForegroundColor Green
