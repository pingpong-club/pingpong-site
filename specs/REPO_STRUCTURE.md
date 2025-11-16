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