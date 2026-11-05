# CommonGround — Assignment 10

Live app: https://jj2cold23.github.io/members-app/
Source: https://github.com/jj2cold23/members-app

A responsive, buildless Members PWA, hosted on GitHub Pages and connected to Supabase Auth and PostgreSQL. No package installation or frontend build is needed.

## Features

- Unique email/password member accounts, sign-in, and sign-out.
- Shared member directory with names, contact emails, and phone numbers.
- Members can edit only their own profiles.
- Shared issues and tasks, including status, member assignment, and optional task due dates.
- Only record creators can update their own issues, tasks, and comments. Task ownership belongs to the creator; assignment alone does not grant editing permission.
- Comments exist only on tasks. Each comment belongs to its author.
- Server-enforced row level security and triggers prevent ownership transfer or moving comments between tasks.
- Installable PWA with manifest, 192/512 icons, service worker, and public app-shell caching. Private member data and API responses are never cached. Reading shared data and saving changes require a connection.

## Run locally

Use Node.js 22 or later:

```sh
npm start
npm test
```

Open http://127.0.0.1:4173. Do not open index.html through file://. The existing public/config.js points to the deployed Supabase project and contains only the public browser key.

## Files

- public/ — complete frontend code and PWA assets; this is the folder deployed to GitHub Pages.
- database/schema.sql — database setup for a NEW Supabase project. Do not rerun it on the already configured live project.
- tests/api.test.js — six passing API-client tests for sessions, refresh, denied updates, errors, and logout.
- tests/ownership.sql — live-verified ownership tests using temporary database fixtures and a final ROLLBACK.
- .github/workflows/pages.yml — GitHub Pages deployment workflow.
- tools/serve.mjs — dependency-free local preview server.

## Verification

- All six API-client tests and JavaScript syntax checks passed.
- The deployed homepage, app scripts, config, manifest, service worker, and PNG install icons returned HTTP 200.
- The sign-in and registration forms were inspected in Chrome. Chrome offered the PWA install control.
- All four database tables have RLS enabled; anonymous reads are denied.
- Live ownership tests confirmed own-record updates, rejected cross-member updates and deletions, rejected forged ownership on inserts, and blocked ownership transfer. Temporary fixtures were rolled back.
- Both confirmed classroom accounts passed live email/password sign-in, automatic-profile checks, authenticated reads of all four tables, and the sign-out endpoint. Destructive CRUD behavior was verified by the rollback-only ownership test rather than adding persistent sample records.

## Work-computer note

This project was developed on a work computer. Environment and API setup restrictions were encountered and resolved. The live app and classroom test login were verified before submission. The verified test login is provided separately in the Canvas submission comment; no server secret is included in this source code.

## Fresh installation reference

For a separate deployment, create a Supabase project, run database/schema.sql once, and put its URL and public publishable key into public/config.js. Never put a server/service-role key in frontend code. Set the Supabase Auth Site URL to your GitHub Pages URL. Upload this source to a GitHub repository and select GitHub Actions in Settings > Pages. The workflow deploys public/ on pushes to main.

References:
https://supabase.com/docs/guides/database/postgres/row-level-security
https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages