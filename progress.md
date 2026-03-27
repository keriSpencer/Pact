# Pact Progress

## Roadmap

### Completed
- [x] **Phase 1: Bootstrap + Organizations + Auth** — Rails 8, Devise invite-only, multi-tenancy, admin/member roles, soft delete, dashboard, user management
- [x] **Phase 2: Contacts** — Contact model, CRUD, assignments, soft delete, search
- [x] **Phase 3: Contact Notes** — Communication tracking, contact types, follow-up dates, completion
- [x] **Phase 4: Tags** — Org-scoped colored tags, contact tagging, index filtering
- [x] **Phase 6: Documents + Folders** — Hierarchical folders, Active Storage, soft delete, versioning
- [x] **Phase 7: Document Sharing** — Token-based external sharing, permission levels, access tracking
- [x] **Phase 8: Signatures** — Full e-signature system (see details below)
- [x] **Phase 9: Search** — Global search across contacts and documents
- [x] **Security Hardening** — CSP, rate limiting, tenant isolation, session management, file integrity
- [x] **Design Audit** — 27 UI/UX fixes applied across all views
- [x] **Dark Mode** — System-preference dark mode across 26+ views
- [x] **Dashboard v2** — Stats, pending signatures, overdue follow-ups, recent activity
- [x] **Heroku Deployment** — PostgreSQL, S3, Resend email, auto-migrations
- [x] **Custom Error Pages** — Quirky 404, 422, 500 pages

### Skipped
- [ ] **Phase 5: Activities** — Audit log (nice-to-have, not needed for core flow)

### Future Considerations
- [ ] Multiple signers per document (routing/ordering)
- [ ] Bulk document operations
- [ ] Calendar view for follow-ups
- [ ] API endpoints for external integrations
- [ ] Custom branding per organization

---

## Signature System Details

### Field Types (9 + Custom)
Signature, Initials, Printed Name, Date Signed, Text, Email, Company, Title, Checkbox, + Custom (user-defined label)

### Placement Editor
- Drag-and-drop field placement on PDF canvas (pdf.js rendering)
- Visual pill buttons for field type selection
- Contextual inspector panel (Apple Keynote-style)
- Inline label editing with real-time PDF preview update
- Signature templates (save/apply field layouts)
- Page navigation for multi-page PDFs

### Signing Experience
- Guided field-by-field stepper with progress indicator
- PDF overlay showing field status (pulsing current, green completed, gray pending)
- Drawn signatures via HTML5 canvas (mouse + touch)
- Draw/Type toggle for signatures and initials
- Date fields filled at exact signing time (not page load)
- Confirmation dialog with timestamp before final submission
- Success page after signing

### Post-Signing
- PDF stamping with HexaPDF (drawn images, typed text, checkmarks)
- Audit certificate PDF generation
- Signed version stored as DocumentVersion
- Version viewer with Original/Signed toggle
- Signer receives copy email with token-based access
- Signed documents preserved on deletion (archived, not destroyed)

---

## Changelog

### March 27, 2026
- Fixed CSP blocking S3 iframe previews
- Fixed Save Template button blocked by CSP (moved to Stimulus)
- Deployed to Heroku production

### March 26, 2026
- Heroku production deployment (PostgreSQL, S3, Resend)
- Fixed Solid Cache/Queue/Cable dependency crash
- Custom error pages (404, 422, 500)

### March 25, 2026
- Dark mode across all views
- Dashboard v2 with signature activity and follow-up reminders
- Send documents for signature from contact show page
- Fix drawn signatures display on PDF preview (image caching)
- Date fields filled at signing time, not page load
- Checkbox labels in stamped PDF
- Larger preview with full-screen button
- Fix signature drawing visibility in Chrome dark mode
- Contextual inspector panel for field editing
- Custom field type pill
- Inline label editing

### March 24, 2026
- Security hardening (10 fixes)
- Tenant isolation (TenantIsolated concern + schema-per-tenant prep)
- Contact picker for signature requests
- All 9 field types fully supported
- Global search

### March 23, 2026
- Initial build: Phases 1-4, 6-8
- Full signature system with drag-and-drop placement
- Drawn signature pad, guided signing stepper
- Signature templates, audit certificates
- Professional email templates
- 174 tests, 261 assertions, 0 failures
