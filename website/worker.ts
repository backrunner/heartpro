interface Env {
  ASSETS: { fetch(request: Request): Promise<Response> };
}

// Support is read-only. Keep a tombstone for cached forms and old clients.
// Never read, log, store or forward an incoming support request body.
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const path = new URL(request.url).pathname;
    if (path === '/api/support' || path.startsWith('/api/support/')) {
      return Response.json({ error: 'support_intake_disabled' }, {
        status: 410, headers: { 'Cache-Control': 'no-store' }
      });
    }
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response(null, { status: 405, headers: { Allow: 'GET, HEAD', 'Cache-Control': 'no-store' } });
    }
    return env.ASSETS.fetch(request);
  }
};
