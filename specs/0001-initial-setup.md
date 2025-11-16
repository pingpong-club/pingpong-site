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