const CACHE_NAME = 'c47-gtk-v1.0.0';
const STATIC_CACHE = 'c47-static-v1';
const BROADWAY_CACHE = 'c47-broadway-v1';

// Cache original GTK assets
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/assets/gtk/icons/calculator.png',
  '/assets/gtk/icons/calculator-48.png',
  '/assets/gtk/icons/calculator-96.png',
  '/assets/gtk/icons/calculator-192.png',
  '/assets/gtk/icons/calculator-512.png'
];

// Broadway server endpoints to cache strategically
const BROADWAY_ENDPOINTS = [
  '/broadway/',
  '/broadway/static/'
];

self.addEventListener('install', event => {
  console.log('Service Worker installing...');
  
  event.waitUntil(
    Promise.all([
      // Cache static GTK assets
      caches.open(STATIC_CACHE).then(cache => {
        console.log('Caching static assets...');
        // Cache only existing assets, don't fail on missing ones
        return Promise.allSettled(
          STATIC_ASSETS.map(url => 
            cache.add(url).catch(err => {
              console.warn(`Failed to cache ${url}:`, err);
            })
          )
        );
      }),
      
      // Prepare Broadway cache
      caches.open(BROADWAY_CACHE).then(cache => {
        console.log('Broadway cache prepared');
        return cache;
      })
    ]).then(() => {
      console.log('✅ C47 GTK assets cached for offline use');
      return self.skipWaiting();
    })
  );
});

self.addEventListener('activate', event => {
  console.log('Service Worker activating...');
  
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== STATIC_CACHE && 
              cacheName !== BROADWAY_CACHE &&
              cacheName !== CACHE_NAME) {
            console.log('Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('Service Worker activated');
      return self.clients.claim();
    })
  );
});

self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  
  // Skip non-HTTP(S) requests
  if (!url.protocol.startsWith('http')) {
    return;
  }
  
  // Handle Broadway WebSocket connections - let them pass through
  if (url.pathname.includes('/broadway/socket') || 
      url.pathname.includes('/ws') ||
      request.headers.get('Upgrade') === 'websocket') {
    return;
  }
  
  // Handle Broadway server requests
  if (url.hostname === 'localhost' && url.port === '8080') {
    event.respondWith(
      fetch(request).catch(() => {
        // Return offline fallback for Broadway
        return new Response(
          `<!DOCTYPE html>
          <html>
          <head>
            <title>C47 Calculator - Offline</title>
            <style>
              body {
                font-family: system-ui, sans-serif;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
              }
              .offline-message {
                text-align: center;
                padding: 40px;
                background: rgba(255,255,255,0.1);
                border-radius: 12px;
                backdrop-filter: blur(10px);
              }
              h1 { margin-bottom: 20px; }
              p { margin-bottom: 30px; opacity: 0.9; }
              button {
                background: white;
                color: #667eea;
                border: none;
                padding: 12px 24px;
                border-radius: 6px;
                font-size: 16px;
                cursor: pointer;
                font-weight: 600;
              }
              button:hover {
                opacity: 0.9;
              }
            </style>
          </head>
          <body>
            <div class="offline-message">
              <h1>📱 C47 Calculator Offline</h1>
              <p>The GTK Broadway server is not available.<br>
                 Please check your connection and try again.</p>
              <button onclick="location.reload()">Retry Connection</button>
            </div>
          </body>
          </html>`,
          { 
            headers: { 
              'Content-Type': 'text/html',
              'Cache-Control': 'no-cache'
            } 
          }
        );
      })
    );
    return;
  }
  
  // Handle static assets with cache-first strategy
  event.respondWith(
    caches.match(request).then(cachedResponse => {
      if (cachedResponse) {
        // Return cached version and update cache in background
        event.waitUntil(
          fetch(request).then(networkResponse => {
            if (networkResponse.ok) {
              return caches.open(STATIC_CACHE).then(cache => {
                cache.put(request, networkResponse.clone());
              });
            }
          }).catch(() => {
            // Silently fail background update
          })
        );
        return cachedResponse;
      }
      
      // Not in cache, fetch from network
      return fetch(request).then(networkResponse => {
        // Only cache successful GET requests
        if (!networkResponse.ok || request.method !== 'GET') {
          return networkResponse;
        }
        
        // Determine which cache to use
        const cacheName = url.pathname.includes('/broadway/') ? 
                         BROADWAY_CACHE : STATIC_CACHE;
        
        // Cache the response
        return caches.open(cacheName).then(cache => {
          cache.put(request, networkResponse.clone());
          return networkResponse;
        });
      }).catch(error => {
        // Network failed, return offline page for navigation requests
        if (request.mode === 'navigate') {
          return caches.match('/index.html').then(cachedPage => {
            if (cachedPage) {
              return cachedPage;
            }
            
            // Even index.html isn't cached, return basic offline page
            return new Response(
              `<!DOCTYPE html>
              <html>
              <head>
                <title>C47 Calculator - Offline</title>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                  body {
                    font-family: system-ui, sans-serif;
                    text-align: center;
                    padding: 50px;
                    background: #f0f0f0;
                  }
                  h1 { color: #e74c3c; }
                  button {
                    margin-top: 20px;
                    padding: 10px 20px;
                    background: #3498db;
                    color: white;
                    border: none;
                    border-radius: 5px;
                    cursor: pointer;
                    font-size: 16px;
                  }
                </style>
              </head>
              <body>
                <h1>📴 Offline</h1>
                <p>C47 Calculator requires an internet connection for initial setup.</p>
                <button onclick="location.reload()">Try Again</button>
              </body>
              </html>`,
              { headers: { 'Content-Type': 'text/html' } }
            );
          });
        }
        
        // For other requests, just fail
        throw error;
      });
    })
  );
});

// Background sync for calculator state
self.addEventListener('sync', event => {
  if (event.tag === 'calculator-state-sync') {
    event.waitUntil(syncCalculatorState());
  }
});

async function syncCalculatorState() {
  try {
    // Attempt to sync calculator memory/programs when back online
    const response = await fetch('/api/sync-state', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        timestamp: new Date().toISOString(),
        version: CACHE_NAME
      })
    });
    
    if (response.ok) {
      console.log('Calculator state synced successfully');
    }
  } catch (error) {
    console.log('State sync failed, will retry:', error);
    throw error;
  }
}

// Handle messages from the main app
self.addEventListener('message', event => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'CLEAR_CACHE') {
    event.waitUntil(
      caches.keys().then(cacheNames => {
        return Promise.all(
          cacheNames.map(cacheName => caches.delete(cacheName))
        );
      }).then(() => {
        console.log('All caches cleared');
      })
    );
  }
});

// Periodic cache cleanup (every 7 days)
self.addEventListener('message', event => {
  if (event.data && event.data.type === 'CLEANUP_CACHE') {
    event.waitUntil(
      caches.open(BROADWAY_CACHE).then(cache => {
        // Remove old Broadway cache entries
        return cache.keys().then(requests => {
          const oneWeekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
          return Promise.all(
            requests.map(request => {
              return cache.match(request).then(response => {
                const dateHeader = response.headers.get('date');
                if (dateHeader) {
                  const responseDate = new Date(dateHeader).getTime();
                  if (responseDate < oneWeekAgo) {
                    return cache.delete(request);
                  }
                }
              });
            })
          );
        });
      })
    );
  }
});