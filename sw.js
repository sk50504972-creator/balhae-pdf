const C = 'balhae-pdf-v2';
self.addEventListener('install', e => { self.skipWaiting(); e.waitUntil(caches.open(C).then(c => c.addAll(['./', './manifest.webmanifest', './icons/icon-192.png'])).catch(() => {})); });
self.addEventListener('activate', e => e.waitUntil((async () => { for (const k of await caches.keys()) if (k !== C) await caches.delete(k); await self.clients.claim(); })()));
// 앱 화면은 항상 서버의 최신본(네트워크 우선, 브라우저 캐시도 재확인), 인터넷이 끊기면 저장해 둔 사본으로 연다.
self.addEventListener('fetch', e => {
  const req = e.request; const u = new URL(req.url);
  if (req.method !== 'GET' || u.origin !== location.origin) return;
  if (u.pathname.endsWith('/version.json')) return;
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
