const C = 'balhae-pdf-v4';
self.addEventListener('install', e => { self.skipWaiting(); e.waitUntil(caches.open(C).then(c => c.addAll(['./', './manifest.webmanifest', './icons/icon-192.png'])).catch(() => {})); });
self.addEventListener('activate', e => e.waitUntil((async () => { for (const k of await caches.keys()) if (k !== C && k !== 'balhae-share') await caches.delete(k); await self.clients.claim(); })()));
self.addEventListener('fetch', e => {
  const req = e.request; const u = new URL(req.url);
  if (u.origin !== location.origin) return;
  // 안드로이드 「공유 → 발해 PDF」: 받은 파일을 잠시 보관하고 편집기로 넘긴다
  if (req.method === 'POST' && u.pathname.endsWith('/share-target')) {
    e.respondWith((async () => {
      try {
        const fd = await req.formData();
        const files = fd.getAll('file').filter(f => f && typeof f !== 'string');
        const c = await caches.open('balhae-share');
        for (const k of await c.keys()) await c.delete(k);
        await c.put('/balhae-pdf/__shared__/meta', new Response(JSON.stringify(files.map((f, i) => ({ i, name: f.name, type: f.type })))));
        for (let i = 0; i < files.length; i++) await c.put('/balhae-pdf/__shared__/' + i, new Response(files[i]));
      } catch (err) {}
      return Response.redirect('/balhae-pdf/?shared=1', 303);
    })());
    return;
  }
  if (req.method !== 'GET' || u.pathname.startsWith('/__native__/')) return;
  if (u.pathname.endsWith('/version.json') || u.pathname.endsWith('/drive-mode.json')) return;
  const nav = req.mode === 'navigate';
  const key = nav ? './' : req;
  e.respondWith(caches.open(C).then(async c => {
    try {
      const r = nav ? await fetch(u.origin + u.pathname, { cache: 'no-cache', credentials: 'same-origin' }) : await fetch(req, { cache: 'no-cache' });
      if (r.ok) c.put(key, r.clone());
      return r;
    } catch (err) {
      const hit = await c.match(key, { ignoreSearch: nav });
      return hit || Response.error();
    }
  }));
});
