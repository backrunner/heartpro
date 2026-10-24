import test from 'node:test';
import assert from 'node:assert/strict';
import worker from '../worker.ts';

for (const path of ['/api/support', '/api/support/', '/api/support/legacy']) {
  for (const method of ['GET', 'POST', 'PUT', 'OPTIONS']) {
    test(`retired support rejects ${method} ${path} without inspecting or forwarding submitted data`, async () => {
      let assetCalls = 0;
      const request = new Request(`https://heartpro.alkinum.com${path}`, { method });
      const guarded = new Proxy(request, {
        get(target, name) {
          if (['body', 'headers', 'json', 'text', 'formData', 'arrayBuffer'].includes(String(name))) throw new Error('Support data must not be accessed');
          return Reflect.get(target, name, target);
        }
      });
      const result = await worker.fetch(guarded, { ASSETS: { async fetch() { assetCalls++; return new Response(); } } });
      assert.equal(result.status, 410);
      assert.deepEqual(await result.json(), { error: 'support_intake_disabled' });
      assert.equal(assetCalls, 0);
    });
  }
}

test('ordinary writes are not forwarded to static assets', async () => {
  const result = await worker.fetch(new Request('https://heartpro.alkinum.com/support/', { method: 'POST' }), {
    ASSETS: { async fetch() { throw new Error('Unexpected forwarding'); } }
  });
  assert.equal(result.status, 405);
});

test('read-only pages are served by the existing asset binding', async () => {
  const request = new Request('https://heartpro.alkinum.com/support/');
  const result = await worker.fetch(request, { ASSETS: { async fetch(value) { assert.equal(value, request); return new Response('static help'); } } });
  assert.equal(await result.text(), 'static help');
});
