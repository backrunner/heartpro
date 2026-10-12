# HeartPro website

The English / Simplified Chinese product site at [heartpro.alkinum.com](https://heartpro.alkinum.com), built with SvelteKit and svedocs. Cloudflare serves the static site and a Worker handles support requests.

## Local development

Use Node.js and pnpm 12.3.4. From this directory:

```sh
rtk proxy pnpm install --frozen-lockfile
rtk proxy pnpm dev --host 127.0.0.1 --port 48620
```

For a production preview, run `rtk proxy pnpm build`, then `rtk proxy pnpm preview --host 127.0.0.1 --port 48622`. Do not run dev and build together; both use `.svelte-kit`. Restart dev after building.

## Structure

- `content/pages/{en,zh}`: landing, support, privacy, terms and availability pages.
- `content/docs/{en,zh}`: usage, data management and analysis methods.
- `src/lib`: shared page layout, theme and bilingual support form.
- `src/lib/server/support-intake.ts` and `worker.ts`: server-side OnFire integration.
- `static/screenshots`: native simulator captures with labelled synthetic examples; `provenance.json` records versions, sources and hashes.
- `svedocs.config.ts`: site metadata, navigation, search, translations and static build.
- `wrangler.jsonc`: production domain, public routing IDs and rate-limit bindings.

English routes start at `/`, Chinese at `/zh/`; guides use `/docs/` and `/docs/zh/`. The framework provides search, theme switching, sitemap, Markdown twins and `llms.txt`.

## Checks

```sh
rtk proxy pnpm check
rtk proxy pnpm check:docs
rtk proxy pnpm test:support
rtk proxy pnpm build
rtk proxy pnpm test
rtk proxy pnpm check:deploy
```

Browser tests cover both languages, navigation, screenshots, support interactions and mobile layouts. Support tests use mock services and do not create production tickets. Deployment checks perform a dry run.

## Secrets and deployment

Local development and static builds do not need production credentials. The support endpoint returns an unavailable response until configured. Use `.env.example` for variable names and keep local secrets in the ignored `.dev.vars`, with file permissions `600`.

The OnFire product credential belongs only in the Worker secret `ONFIRE_API_KEY`. Never put it in `PUBLIC_*`, browser code, tracked files or command-line arguments. Public Turnstile site keys and routing IDs are configuration, not secrets. OnFire owns CAPTCHA verification; the website must not consume the same token twice. The server checks origin and input bounds, owns product/type routing, rejects redirects and does not retry uncertain ticket writes.

Maintainers with deployment access can build, run checks, then use `rtk proxy pnpm run deploy`. A fork must configure its own domain, bindings, product IDs and credentials before deploying. `run` is required here because pnpm has a separate built-in `deploy` command.

Production support tests create real tickets and require explicit authorization. The site does not accept health-record, file or diagnostic-log uploads. Verify support-email delivery separately from a successful ticket submission. Server logs must not contain request bodies, email addresses, credentials or raw upstream responses.

Source is covered by the repository’s [GPL-3.0-or-later license](../LICENSE); see [third-party notices](../THIRD_PARTY_NOTICES.md).
