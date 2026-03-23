# Pact Progress

## Roadmap

### Completed
- [x] **Phase 1: Bootstrap + Organizations + Auth** - Rails 8 app, Devise invite-only, multi-tenancy, admin/member roles, soft delete, dashboard, user management

### In Progress
- [ ] **Phase 2: Contacts** - Contact model, CRUD, assignments, soft delete

### Planned
- [ ] **Phase 3: Contact Notes** - Communication tracking, follow-ups
- [ ] **Phase 4: Tags** - Org-scoped tags with colors, contact tagging
- [ ] **Phase 5: Activities** - Polymorphic audit log
- [ ] **Phase 6: Documents + Folders** - Hierarchical folders, Active Storage, versioning
- [ ] **Phase 7: Document Sharing** - Internal + external sharing, tokens, permissions
- [ ] **Phase 8: Signature Requests** - Multi-field signing, PDF stamping, templates, public signing
- [ ] **Phase 9: Search** - Global search across contacts + documents

---

## Changelog

### March 23, 2026

#### Phase 1: Bootstrap + Organizations + Auth
- Generated Rails 8.0.4 app (Tailwind, Hotwire, importmap, Propshaft)
- Full Gemfile: Devise, devise_invitable, HexaPDF, Pagy, AWS S3, factory_bot, shoulda-matchers, Faker, Brakeman, RuboCop
- Organization model: name, slug (auto-generated), description, active, validations
- User model: Devise invite-only (no registration), admin/member enum, soft delete, permission helpers
- Authorization + OrganizationScoped controller concerns
- Dashboard with contact count, org info, team count
- User profile with edit, admin user management with delete/restore/role
- Invitation system (admin-only)
- Apple-style UI: sticky nav, mobile bottom tabs, flash messages
- Port 3003 (Puma + Procfile.dev)
- Demo seeds: demo@pactapp.com / demo1234
- 33 tests, 53 assertions, 0 failures
