# Chat transcript — 2025-11-15 (summary)

Summary of decisions and steps captured. Request a full verbatim transcript if needed; it will be lengthy and can be added later.

- Hugo + FixIt via Hugo Modules with vendored snapshot
- site/ subdirectory for Hugo; specs/ for docs
- Netlify-managed builds (GitHub App), base=site, command=hugo --minify, publish=public
- Cloudflare DNS + Email Routing (receive-only); SPF: v=spf1 -all, DMARC: p=reject
- Events filtered at build time; nightly GitHub Action calls Netlify Build Hook
- Ownership: GitHub org (pingpong-club), private repo; Netlify Free seat considerations