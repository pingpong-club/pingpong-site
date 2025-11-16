# Next Steps — Ping Pong Club Site

## Status
- ✅ Repository created: `pingpong-club/pingpong-site`
- ✅ Conversation transcript documented
- ⏳ Site scaffold pending (files not yet committed)

## Immediate Actions

### 1. Create Site Scaffold (Choose One Approach)

**Option A: Run Bootstrap Script (Recommended)**
```powershell
# In repo root (PowerShell)
.\scripts\bootstrap.ps1
```
Creates all files, vendors FixIt theme, commits to `scaffold` branch, pushes, and attempts PR.

**Option B: Manual File Creation**
Use the file content from the transcript (Part 4-5) to create each file manually.

### 2. Review & Merge PR
- [ ] Your son reviews the `scaffold` branch PR
- [ ] Merge to `main` after approval
- [ ] Pull latest `main` locally

### 3. Local Verification
```powershell
cd site
hugo server -D
```
Visit http://localhost:1313 to verify the site works.

### 4. Cloudflare Setup
- [ ] Register domain: `pingpongclub.org`
- [ ] Update nameservers to Cloudflare
- [ ] Configure Email Routing: `webmaster@pingpongclub.org` → `ag@bec.com`
- [ ] Add DNS records:
  - SPF (TXT @): `v=spf1 -all`
  - DMARC (TXT _dmarc): `v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s`
- [ ] Invite son as Cloudflare Member for future handoff

### 5. Netlify Deployment
- [ ] Create Netlify team (Free/Starter tier)
- [ ] Install Netlify GitHub App for `pingpong-club` org
- [ ] Import repo: pingpong-club/pingpong-site
- [ ] Verify build settings (auto-detected from `netlify.toml`):
  - Base: `site`
  - Command: `hugo --minify`
  - Publish: `public`
  - Env: `HUGO_VERSION=0.134.3`
- [ ] Test deploy and verify site

### 6. Nightly Rebuild Setup (Auto-expire Past Events)
- [ ] In Netlify: Site Settings → Build & Deploy → Build Hooks
- [ ] Create build hook: "nightly-rebuild"
- [ ] Copy the hook URL
- [ ] In GitHub: Settings → Secrets and variables → Actions
- [ ] Add secret: `NETLIFY_BUILD_HOOK_URL` = hook URL
- [ ] Verify workflow: Actions → Nightly Netlify Rebuild → Run workflow (manual test)

### 7. Custom Domain
- [ ] In Netlify: Domain settings → Add custom domain
- [ ] Enter: `pingpongclub.org`
- [ ] Update DNS in Cloudflare (Netlify provides records)
- [ ] Enable HTTPS (auto via Let's Encrypt)

## Next Content Tasks

### Events System
- [ ] Create real events (replace sample)
- [ ] Test event filtering (create past event, verify it hides after nightly build)
- [ ] Document event creation workflow for club officers

### Site Content
- [ ] Add club information page
- [ ] Add contact/join page
- [ ] Add photos/media gallery (if needed)
- [ ] Customize homepage
- [ ] Update footer with school/club details

### Theme Customization
- [ ] Review FixIt theme documentation
- [ ] Customize colors/branding
- [ ] Add club logo
- [ ] Adjust layout as needed (all overrides in `site/layouts/`)

## Future Considerations

### Access & Handoff
- [ ] Document transfer process in `specs/HANDOFF.md`
- [ ] GitHub: Son can fork or transfer repo when ready
- [ ] Netlify: Transfer site or add as member (requires paid plan)
- [ ] Cloudflare: Update Members when leadership changes
- [ ] Email routing: Update forwarding targets

### Optional Enhancements
- [ ] Preview deploys for PRs (already enabled, toggle in Netlify settings)
- [ ] Analytics (Netlify Analytics or external)
- [ ] Contact form (Netlify Forms)
- [ ] Search functionality (FixIt includes options)
- [ ] Multiple authors/contributors
- [ ] Blog/news section

## Troubleshooting

### Hugo Build Fails
- Verify Hugo Extended is installed: `hugo version`
- Check Go toolchain if module errors occur
- Ensure `_vendor/` was committed

### Netlify Build Fails
- Check deploy log in Netlify dashboard
- Verify `HUGO_VERSION` matches local version
- Confirm `base = "site"` in netlify.toml

### Events Not Filtering
- Verify date format is ISO 8601: `2025-11-20`
- Check event's `active: true` param
- Wait until after nightly build runs (or trigger manual deploy)

### GitHub Actions Failing
- Verify `NETLIFY_BUILD_HOOK_URL` secret is set
- Test build hook manually: `curl -X POST [hook-url]`
- Check Actions logs for error details

## Resources

- [Hugo Documentation](https://gohugo.io/documentation/)
- [FixIt Theme Docs](https://fixit.lruihao.cn/)
- [Netlify Docs](https://docs.netlify.com/)
- [Cloudflare Docs](https://developers.cloudflare.com/)
- Transcript: `specs/AIChat251115.md`
- Setup checklist: `specs/0001-initial-setup.md`
- Structure: `specs/REPO_STRUCTURE.md`

## Questions/Issues?

If you encounter issues:
1. Check the transcript for context
2. Review Hugo/FixIt/Netlify docs
3. Ask in VS Code with Copilot (include relevant files as context)
4. GitHub Issues for tracking with your son
