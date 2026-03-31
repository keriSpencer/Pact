# Pact Progress

## Roadmap

### Completed
- [x] **Phase 1: Bootstrap + Organizations + Auth** — Rails 8, Devise, multi-tenancy, admin/member roles, soft delete, dashboard, user management
- [x] **Phase 2: Contacts** — Contact model, CRUD, assignments, soft delete, search
- [x] **Phase 3: Contact Notes** — Communication tracking, contact types, follow-up dates, completion
- [x] **Phase 4: Tags** — Org-scoped colored tags, contact tagging, index filtering
- [x] **Phase 6: Documents + Folders** — Hierarchical folders, Active Storage, soft delete, versioning
- [x] **Phase 7: Document Sharing** — Token-based external sharing, permission levels, access tracking
- [x] **Phase 8: Signatures** — Full e-signature system (single + multi-signer)
- [x] **Phase 9: Search** — Global search across contacts and documents
- [x] **Security Hardening** — CSP, rate limiting, tenant isolation, session management, file integrity
- [x] **Design Audit** — 27 UI/UX fixes applied across all views
- [x] **Dark Mode** — System-preference dark mode across 26+ views
- [x] **Dashboard v2** — Stats, pending signatures, overdue follow-ups, recent activity
- [x] **Heroku Deployment** — PostgreSQL, S3, Resend email, custom domain (pactapp.io)
- [x] **Custom Error Pages** — Quirky 404, 422, 500 pages
- [x] **Ruby/Rails Upgrade** — Ruby 3.4.4, Rails 8.1.3
- [x] **Mobile Responsive Polish** — Headers stack, buttons wrap, touch-friendly
- [x] **First-Time Empty States** — Welcome onboarding, "All clear" messages
- [x] **Multi-Signer Documents** — Envelope pattern, parallel/sequential, self-sign, per-signer tokens
- [x] **Stripe Billing** — 3-tier pricing, trial, portal (partner contribution)
- [x] **Public Landing Page** — Hero, pricing, contact form (partner contribution)
- [x] **Self-Service Registration** — Auto org creation, welcome email (partner contribution)
- [x] **RubyNative iOS App** — Native shell, push notifications (partner contribution)
- [x] **Brand Kit** — Favicon, logos, OG image (partner contribution)
- [x] **REST API (v1)** — Token auth, documents, folders, sync endpoints for PactSync (partner contribution)
- [x] **PactSync Desktop App** — macOS sync app, landing page, setup guide (partner contribution)
- [x] **Folder Sharing** — Share folders internally/externally, cross-org, email notifications, public links (partner contribution)
- [x] **Document Quick Share** — Copyable share links with Turbo Stream UI (partner contribution)

### Skipped
- [ ] **Phase 5: Activities** — Audit log (nice-to-have, not needed for core flow)

### Up Next
- [ ] **Google OAuth** — Sign in with Google
- [ ] **Password show/hide toggle** — Eye icon on login/signup forms
- [ ] **Reuse drawn signature** — Pre-fill subsequent fields after first signature
- [ ] **Snap-to-align guides** — Alignment lines when placing fields (Keynote-style)
- [ ] **Accessibility: non-color indicators** — Signer initials/labels on fields for colorblind users
- [ ] **Signer field visibility toggles** — Eye icon to show/hide each signer's fields
- [ ] **Live-update signer dropdown** — Reflect name changes in assignment dropdown
- [ ] **Collapse completed envelopes** — Don't push preview off-screen
- [ ] **Per-envelope signed PDF view** — Each envelope card links to its specific signed version
- [ ] **Saved signature in profile** — Store drawn signature for reuse across sessions
- [ ] Bulk document operations
- [ ] Calendar view for follow-ups
- [ ] API endpoints for external integrations

---

## Multi-Signer Architecture

### Envelope Pattern
- `SigningEnvelope` coordinates multiple `SigningRole` records per document
- Each role has a label, color, email, name, and signing order
- Each role gets its own `SignatureRequest` with a unique token
- Fields are assigned to roles via `signing_role_id`

### Signing Modes
- **Parallel**: all signers receive links immediately, sign independently
- **Sequential**: signers sign in order, each notified when it's their turn

### Self-Sign
- Admin can mark themselves as a signer (toggle on role)
- Fields auto-completed with admin's name on activation
- No email sent to self

### Completion
- When all signers finish: all-party PDF stamped, requester notified
- Document show page shows envelope progress with per-signer status

---

## Changelog

### March 30, 2026
- Multi-signer documents (Phases 1-8): envelope pattern, signing roles,
  parallel/sequential mode, self-sign, per-signer tokens, multi-signer
  PDF stamping, all-signers-completed notifications
- Fix: signer data persists when adding/removing signers
- Fix: active signer highlight visible in dark mode
- Fix: field reassignment dropdown with signer names
- Fix: never expose drawn signatures to other signers (privacy/security)
- Fix: page crash from rendering base64 data as text
- Merged partner's changes: Stripe billing, landing page, RubyNative,
  brand kit, registration, timezone support, mobile fixes

### March 31, 2026
- Merged partner's changes:
  - REST API v1 (token auth, documents, folders, sync) for PactSync desktop app
  - PactSync macOS app (1.0.0 DMG, landing page, setup guide)
  - Folder sharing (internal/external, cross-org, email notifications, public token links)
  - Document quick share (copyable links, Turbo Stream UI)
  - 26 new tests (214 total, 342 assertions, 0 failures)

### March 28, 2026
- Custom domain: pactapp.io
- Resend SMTP email configuration

### March 27, 2026
- Ruby 3.4.4, Rails 8.1.3 upgrade
- Dark mode across all views
- Dashboard v2 with signature activity
- Send for signature from contact show page
- Custom error pages
- Heroku production deployment
- S3 file storage, CSP fixes

### March 25-26, 2026
- Guided signing stepper, drawn signatures, all 9 field types
- Contextual inspector panel, inline label editing
- Date fields at signing time, dark mode for signing canvas
- Contact picker, search, security hardening

### March 23-24, 2026
- Initial build: all core features
- 188 tests, 278 assertions, 0 failures
