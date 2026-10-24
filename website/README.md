# HeartPro website

English / Simplified Chinese product and read-only help site at [heartpro.alkinum.com](https://heartpro.alkinum.com), built with SvelteKit and svedocs. The help pages do not accept support messages, personal information or files.

## Development

Use the configured Node.js and pnpm. From this directory:

```sh
rtk proxy pnpm install --frozen-lockfile
rtk proxy pnpm dev --host 127.0.0.1 --port 48620
```

Production preview: build, then `rtk proxy pnpm preview --host 127.0.0.1 --port 48622`. Do not run dev and build together; both use `.svelte-kit`.

## Structure and privacy boundary

- `content/pages/{en,zh}`: product, static help, privacy, terms and availability.
- `content/docs/{en,zh}`: record controls, data handling, calculation methods and cited sources.
- `worker.ts`: serves static assets and rejects the former `/api/support` endpoint with 410, without reading or forwarding the body. Non-read requests handled by the Worker are rejected.
- `wrangler.jsonc`: asset binding, disabled observability and retired-endpoint routing. No support-provider configuration, rate limiter or ticket integration.
- `static/screenshots`: synthetic native previews with recorded provenance; not evidence of a newly uploaded build.

The support form, OnFire client, customer identification, Turnstile widget and support routing bindings were removed on 2026-10-24. Deploying this source prevents new intake but does not itself delete historical messages or remote credentials. Builds do not need support secrets. Do not restore collection by accepting legacy credentials from local or deployed environments. Cloudflare necessarily processes network requests to deliver and protect the site; the privacy policy discloses that separately.

## Verification and deployment

```sh
rtk proxy pnpm check
rtk proxy pnpm check:docs
rtk proxy pnpm test:support
rtk proxy pnpm build
rtk proxy pnpm test
rtk proxy pnpm check:deploy
rtk proxy pnpm run deploy
```

The support tests assert that retired endpoints do not access request bodies or headers and do not forward requests. Browser tests cover both help languages, no form or mail submission, no ticket/CAPTCHA requests, responsive layouts and help without JavaScript. Verify deployed GET and synthetic POST requests return 410 without supplying personal data. Do not create production tickets as a test.

The deployment is separate from App Store/TestFlight distribution. It does not upload an app or resubmit Apple review. Source is [GPL-3.0-or-later](../LICENSE).
