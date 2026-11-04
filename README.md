# CommonGround — Assignment 10

A buildless, responsive Members PWA for GitHub Pages. Uses Supabase Auth for unique email/password logins and PostgreSQL row level security (RLS) for server-enforced ownership. No npm dependencies or build step.

**Current status:** source code is prepared; not deployed or connected to a backend. `public/config.js` must be configured before accounts/data work. No working login has been created yet.

## Fastest setup

1. Create a free Supabase project at https://supabase.com/dashboard (keep the database password private).
2. Run `database/schema.sql` once in its SQL Editor **before** creating users. This creates profiles automatically for new signups.
3. In project Settings → API, copy the project URL and public publishable (or legacy anon) key into `public/config.js`. Never use the secret/service-role key.
4. In Authentication → URL Configuration, set Site URL to `https://jj2cold23.github.io/members-app/` (adjust if your repository name differs). Keep email/password signups enabled. Email confirmation is supported; users confirm their email then return to sign in. For a classroom project, you can instead disable email confirmation before creating test accounts.
5. Create a **public** GitHub repository called `members-app`. Upload this folder's contents with the structure intact. Include `.github/workflows/pages.yml`; it is a hidden folder on some systems. In repository Settings → Pages, set Source to **GitHub Actions**. The included workflow deploys only `public/` on a push to `main`.
6. Wait for the “Deploy Members PWA” workflow to succeed. Open `https://jj2cold23.github.io/members-app/`. The relative paths also work under other repository names.
7. Create two member accounts through the app and test the checklist below. Use a classroom-only password, never a reused personal password. The README and submission comment must be updated with a **real account you created**, not an invented account.
8. Zip this folder after configuration. Submit the ZIP, the live link, and the login comment below.

The outer submission ZIP contains this README, database setup, workflow, tests, and all frontend code. Only `public/` is deployed.

## Submission comment — fill after creating the test account

```text
Live site: https://jj2cold23.github.io/members-app/
Test member email: [actual account email]
Test member password: [actual classroom-only password]
```

No real password is embedded in the source. This template is not a valid login credential until filled in.

## Local preview and checks

Install Node.js 22 or later, then run from this folder:

```sh
npm start
npm test
```

Open http://127.0.0.1:4173. No `npm install` is necessary. Supabase still needs configuration. Do not open index.html through `file://` because service workers require HTTPS or localhost.

## Ownership decisions

- Signed-in members can read all member profiles, issues, tasks, and comments. Signed-out users have no data access.
- Each profile belongs to its authenticated user ID. Only that member may update it. Profile deletion and manual creation are unavailable to browser clients.
- The creator owns an issue, task, or comment. Only its owner can edit or delete it. Task assignee is a separate field: assignment alone does not grant editing rights. Any signed-in member can assign a new task to any member.
- IDs, ownership, creation dates, and a comment's parent task cannot be changed after creation, even using direct API requests.
- Comments require a real task foreign key; there are no issue comments. Deleting a task deletes its associated comments.
- Profile email is contact information. Changing it does not change the Auth login identity. Supabase enforces login email uniqueness.
- All changes save to the shared database, not localStorage. Session tokens live in sessionStorage for the browser tab. Passwords are sent to Supabase Auth over HTTPS and never stored by this frontend.

## PWA behavior

Includes a manifest, 192/512 PNG icons, a same-origin service worker, and install support where the browser offers it. The public app shell can reopen offline after one successful visit. Offline member data and offline writes are intentionally unavailable: authenticated responses are never cached. Reconnect to read or save. Install using Chrome/Edge's install control or Safari's Add to Home Screen. HTTPS is provided by GitHub Pages.

## Required live acceptance check

1. As member A, edit your name, email, and phone. Refresh and check persistence.
2. As A, create an issue and a task assigned to member B. Post a task comment.
3. In a separate browser/profile, sign in as B. Confirm A's changes are visible, A's edit controls are absent, and B can create their own issue, task, and comment.
4. Using B's authenticated API token, attempt PATCH requests to A's profile, issue, task, and comment. They must return no updated rows; re-read as A to confirm values stayed unchanged. This is the essential RLS verification; hiding UI controls alone is insufficient.
5. As A, attempt to transfer owner_id to B or move a comment to a different task through the API. Both must fail. Attempting to insert an issue with B's owner_id must fail.
6. Confirm each member can edit their own records. Comments appear only within tasks. Test required fields and empty/long values.
7. Test sign-out, invalid passwords, a second account with the same login email, email confirmation (if enabled), and a page reload while signed in.
8. Install on a phone or desktop, visit once online, then reopen offline. Verify the offline notice and that writes fail clearly. Reconnect and refresh. Test at a narrow mobile width.

## Verification limits

Six automated tests passed. They exercise the API client with mocked responses, including token refresh, unauthorized updates, errors, and logout. JavaScript syntax checks passed. The local app was opened in Chrome, the sign-in layout was visually inspected, the account creation form was checked, and Chrome offered the PWA install control. Authenticated views, live database policies, and deployment remain unverified. Run the live checklist after setting up your project. The SQL uses server-side RLS and immutable-field triggers; no client-provided ownership claim is trusted without checking auth.uid().

References: https://supabase.com/docs/guides/database/postgres/row-level-security and https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages
