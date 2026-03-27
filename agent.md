# Pact - Agent Work Log

## Project Overview
Pact is a Contacts + Document Signing application. Multi-tenant contact management with full e-signature capabilities — drag-and-drop field placement, drawn signatures, guided signing stepper, PDF stamping, audit certificates.

## Current Status: Production on Heroku

### Tech Stack
- Ruby 3.2.0, Rails 8.0.4
- Hotwire (Turbo + Stimulus), importmap-rails, Tailwind CSS v4, Propshaft
- SQLite3 (dev/test), PostgreSQL (production)
- Devise + devise_invitable (invite-only auth)
- HexaPDF (PDF stamping + audit certificates)
- AWS S3 (production file storage), Resend (production email)
- Heroku deployment with auto-migrations

### Features Built

**Core:**
- Multi-tenant organizations with slug-based routing
- Invite-only auth (Devise), admin/member roles, soft delete, session timeout
- Contacts with assignments, notes, tags, follow-ups
- Contact picker with autocomplete for signature requests
- Global search across contacts and documents

**Documents:**
- Hierarchical folders with soft delete
- Active Storage uploads (local dev, S3 production)
- Document versioning (original, signed, audit certificate)
- Version viewer with Original/Signed toggle tabs
- Full-screen preview, document archiving for legal compliance
- Link documents to contacts after the fact

**Signatures (full e-signature system):**
- 9 field types: Signature, Initials, Printed Name, Date, Text, Email, Company, Title, Checkbox + Custom
- Drag-and-drop field placement on PDF canvas (pdf.js)
- Contextual inspector panel (Apple-style — type picker vs field editor)
- Drawn signature pad (HTML5 canvas, mouse + touch)
- Draw/Type toggle for signatures and initials
- Guided signing stepper with progress indicator
- Field-by-field completion with PDF overlay preview
- Actual signature/text content rendered on PDF preview (not just checkmarks)
- Date fields filled at exact signing time (not page load)
- Confirmation dialog with timestamp before submission
- Signature templates (save + reuse field layouts)
- PDF stamping with HexaPDF (signatures, text, checkmarks, audit footer)
- Audit certificate PDF generation
- Public signing page (no login required, via token)
- Signer copy email with token-based document access
- Contact auto-matching by email

**Security:**
- Content Security Policy enabled
- Rate limiting on public endpoints (60/min/IP)
- Tenant isolation (default_scope + before_save guard)
- PostgreSQL schema-per-tenant ready for production
- Session timeout (30 min), remember-me (2 weeks)
- File integrity verification (SHA256 hash check on download)
- Token params filtered from logs

**UX/Design:**
- Apple-style design (clean, minimal, whitespace-driven)
- Full dark mode (system preference, 26+ views)
- Dashboard with stats, pending signatures, overdue follow-ups, recent activity
- Custom error pages (404, 422, 500) with personality
- Responsive mobile layout with bottom tab bar
- Smooth transitions, loading states, hover effects
- Professional branded email templates

**Test suite: 174 tests, 261 assertions, 0 failures**
