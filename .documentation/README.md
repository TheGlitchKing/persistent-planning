---
title: Documentation
tier: reference
domains:
  - database
  - procedures
audience:
  - developers
  - devops
  - admin
tags:
  - api
  - database
  - testing
  - security
status: draft
last_updated: '2026-08-31'
version: 1.0.0
purpose: This documentation system uses a hierarchical, domain-based structure
  for optimal organization and discoverability.
estimated_read_time: 2 minutes
word_count: 250
last_validated: '2026-08-31'
backlinks: []
---

# Documentation

This documentation system uses a hierarchical, domain-based structure for optimal organization and discoverability.

## Quick Navigation

- **[INDEX.md](INDEX.md)** - Complete document listing with metadata
- **[REGISTRY.md](REGISTRY.md)** - Quick reference tables

## Domains

| Domain | Description |
|--------|-------------|
| [agents](agents/) | Expert agent documentation, specialty matrix |
| [api](api/) | API endpoints, routes, specifications, contracts |
| [architecture](architecture/) | System design, AI coach, project registry, patterns |
| [backups](backups/) | Backup/restore guides, disaster recovery |
| [database](database/) | Schema, migrations, RLS, queries, procedures |
| [devops](devops/) | Deployment, CI/CD, Docker, environments, infrastructure |
| [features](features/) | Feature implementation guides, admin docs |
| [plans](plans/) | Planning documents, roadmaps, proposals |
| [procedures](procedures/) | Step-by-step operational procedures (SOP) |
| [quickstart](quickstart/) | Setup guides, dev workflow, onboarding |
| [security](security/) | Security, auth, Vault, Keycloak, RLS |
| [standards](standards/) | Coding standards (backend, frontend, database, devops, security) |
| [testing](testing/) | Test strategies, fixtures, patterns, integration/e2e |
| [troubleshooting](troubleshooting/) | Debug guides, common issues, solutions |
| [workflows](workflows/) | Process documentation, multi-step operations |

## Adding New Documentation

1. Identify the correct domain for your document
2. Create the file in the domain directory
3. Add YAML frontmatter with required metadata
4. Run `npx hit-em-with-the-docs integrate <file>` to register

## Metadata Schema

Every document should include:

```yaml
---
title: "Document Title"
tier: guide|standard|example|reference|admin
domains: [primary-domain]
status: draft|active|deprecated|archived
last_updated: 'YYYY-MM-DD'
version: '1.0.0'
---
```

## Maintenance

Run weekly maintenance with:

```bash
npx hit-em-with-the-docs maintain
```

This will:
- Sync metadata across all documents
- Check for broken links
- Audit compliance
- Generate health reports
