# Pact - Agent Work Log

## Project Overview
Pact is a Contacts + Document Signing application. Multi-tenant contact management with full e-signature capabilities — single and multi-signer support, drag-and-drop field placement, drawn signatures, guided signing stepper, PDF stamping, audit certificates.

## Current Status: Production on Heroku (pactapp.io)

### Tech Stack
- Ruby 3.4.4, Rails 8.1.3
- Hotwire (Turbo + Stimulus), importmap-rails, Tailwind CSS v4, Propshaft
- SQLite3 (dev/test), PostgreSQL (production)
- Devise + devise_invitable (auth with self-registration)
- Stripe (subscription billing with 3-tier pricing)
- HexaPDF (PDF stamping + audit certificates)
- AWS S3 (production file storage), Resend (production email via SMTP)
- RubyNative (iOS native app support)
- Heroku deployment with auto-migrations

### Features Built

**Core:**
- Multi-tenant organizations with slug-based routing
- Self-service registration with auto org creation + 14-day trial
- Stripe subscription billing (Starter/Pro plans)
- Invite-only team management, admin/member roles, soft delete, session timeout
- Contacts with assignments, notes, tags, follow-ups
- Contact picker with autocomplete for signature requests
- Global search across contacts and documents
- Public landing page + contact form

**Documents:**
- Hierarchical folders with soft delete
- Active Storage uploads (local dev, S3 production)
- Document versioning (original, signed, audit certificate)
- Version viewer with Original/Signed toggle tabs
- Full-screen preview (toolbar-free PDF embedding)
- Document archiving for legal compliance
- Link documents to contacts after the fact

**Signatures (full e-signature system):**
- 9 field types: Signature, Initials, Printed Name, Date, Text, Email, Company, Title, Checkbox + Custom
- **Multi-signer support (Envelope pattern):**
  - SigningEnvelope coordinates multiple signers per document
  - SigningRoles with labels, colors, per-signer email/name
  - Parallel mode (everyone signs at once) or Sequential (sign in order)
  - Admin self-sign (sign your own fields without email)
  - Per-signer token links — each signer sees only their fields
  - Other signers' completed fields shown as gray overlays
  - Sequential gating: "Waiting for your turn" screen
  - Envelope completion: PDF stamped with all signatures when all sign
- Drag-and-drop field placement on PDF canvas (pdf.js)
- Contextual inspector panel (Apple-style — type picker vs field editor)
- Drawn signature pad (HTML5 canvas, mouse + touch)
- Draw/Type toggle for signatures and initials
- Guided signing stepper with progress indicator
- Field-by-field completion with actual content rendered on PDF preview
- Date fields filled at exact signing time (not page load)
- Confirmation dialog with timestamp before submission
- Signature templates (save + reuse field layouts)
- PDF stamping with HexaPDF (drawn images, typed text, checkmarks, audit footer)
- Audit certificate PDF generation
- Public signing page (no login required, via token)
- Signer copy email with token-based document access + download
- Contact auto-matching by email
- Send for signature from contact show page

**Security:**
- Content Security Policy enabled (S3 + CDN allowed)
- Rate limiting on public endpoints (60/min/IP)
- Tenant isolation (default_scope + before_save guard)
- PostgreSQL schema-per-tenant ready for production
- Session timeout (30 min), remember-me (2 weeks), timeoutable
- File integrity verification (SHA256 hash check on download)
- Token params filtered from logs

**UX/Design:**
- Apple-style design (clean, minimal, whitespace-driven)
- Full dark mode (system preference, 26+ views)
- Dashboard with stats, pending signatures, overdue follow-ups, recent activity
- Welcome onboarding for first-time users
- Custom error pages (404, 422, 500) with personality
- Responsive mobile layout (headers stack, buttons wrap, bottom tab bar)
- Smooth transitions, loading states, hover effects
- Professional branded email templates (HTML + text)
- Brand kit (favicon, logos, OG image)

**Native App:**
- RubyNative iOS app support
- Push notifications for signed documents
- Profile tab for native users

**Test suite: 188 tests, 278 assertions, 0 failures**
