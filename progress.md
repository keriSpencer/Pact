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

### Recently Completed (March 31 - April 1)
- [x] **Password show/hide toggle** — Eye icon on all password fields
- [x] **Reuse drawn signature** — "Use previous" button on subsequent fields
- [x] **Snap-to-align guides** — Blue guide lines when dragging fields (Keynote-style)
- [x] **Accessibility: non-color indicators** — Role badges (S1, S2) on fields, colorblind-safe palette
- [x] **Signer field visibility toggles** — Eye icon to show/hide each signer's fields
- [x] **Live-update signer dropdown** — Real-time name updates in assignment dropdown
- [x] **Collapse completed envelopes** — Only latest expanded, older ones collapsed
- [x] **Per-envelope signed PDF view** — View/Download buttons on each completed envelope
- [x] **Auto-refresh document status** — Page polls and reloads when signatures complete
- [x] **Preview filename prefix** — "Pact - Document Name" in browser tabs
- [x] **Convert single→multi-signer** — Switch modes without losing placed fields
- [x] **Cross-compatible templates** — Templates work across single/multi-signer modes

### Recently Completed (April 1-3)
- [x] **Admin self-sign in editor** — Draw signature before sending (DocuSign-style)
- [x] **Signature reuse in self-sign** — "Use previous" on subsequent fields
- [x] **Unified signature editor** — One "Request Signature" flow, seamlessly add signers
- [x] **Validate signers have fields** — Block send if any signer has no fields assigned
- [x] **Timestamps on envelope cards** — Sent, viewed, signed dates per signer
- [x] **Send signed copy to recipients** — Email signed PDF to additional parties post-signing
- [x] **Saved signature in profile** — Draw/type signature, encrypted at rest, integrated into self-sign
- [x] **Outstanding signature requests dashboard** — (pending)
- [x] **Automatic follow-up reminders** — (pending)

### Up Next
- [ ] **Google OAuth** — Sign in with Google
- [ ] **Outstanding signature requests dashboard** — Central view of all pending requests
- [ ] **Automatic follow-up reminders** — Scheduled reminders for unsigned requests
- [ ] Bulk document operations
- [ ] Calendar view for follow-ups

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

### March 31 - April 1, 2026
- Password show/hide toggle on all auth forms
- Collapse completed envelopes (latest expanded, older collapsed)
- Per-envelope "View Signed PDF" / "Download" buttons
- Signature reuse: "Use previous signature" on subsequent fields
- Accessibility: role badges (S1, S2), colorblind-safe colors
- Signer field visibility toggles (eye icon, Figma-style)
- Live-update signer dropdown when typing names
- Snap-to-align guides (Keynote-style blue guide lines)
- Auto-refresh document page when signatures complete (15s poll)
- Preview tab shows "Pact - Document Name"
- Convert single→multi-signer without losing fields
- Cross-compatible templates (single↔multi-signer)
- Fix: badge labels show "S1" not "Si"
- Fix: visibility toggle hides ALL fields for a signer (type mismatch)
- Fix: fields preserved when converting single→multi
- Merged partner's changes:
  - REST API v1 (token auth, documents, folders, sync) for PactSync desktop app
  - PactSync macOS app (1.0.0 DMG, landing page, setup guide)
  - Folder sharing (internal/external, cross-org, email notifications, public token links)
  - Document quick share (copyable links, Turbo Stream UI)
- 214 tests, 342 assertions, 0 failures

### April 1-3, 2026
- Admin self-sign in editor (DocuSign-style): draw signature before sending
- Self-sign fields show pulsing "Sign" badge, inline draw/type pad
- Send button disabled until all self-sign fields completed
- Signature reuse in self-sign editor ("Use previous signature")
- Unified signature editor: one "Request Signature" flow for single + multi-signer
- Validate all signers have fields before sending (prevents stuck envelopes)
- Timestamps on envelope signer cards (sent, viewed, signed)
- Send signed copy to additional recipients (PDF attached to email)
- Saved signature in profile (encrypted at rest, integrated into self-sign)
- Fix: self-sign fields draggable on canvas (click = sign, drag = move)
- Fix: signed PDF download on multi-signer confirmation page
- Fix: admin name shown in "Assigned to" dropdown for self-signer roles
- Fix: multi-signer amber message when waiting for other signers

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
