# Собирает установочную версию (PWA) из app.html в папку docs\
# Запуск:  powershell -ExecutionPolicy Bypass -File build.ps1
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$site = Join-Path $here 'docs'   # GitHub Pages раздаёт сайт из папки docs
New-Item -ItemType Directory -Force $site | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText((Join-Path $site '.nojekyll'), '', $utf8)

# 1. index.html = полноценный документ вокруг app.html + манифест и service worker
$body = [IO.File]::ReadAllText((Join-Path $here 'app.html'), [Text.Encoding]::UTF8)
$head = '<!doctype html><html lang="ru"><head><meta charset="utf-8">' +
  '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">' +
  '<meta name="theme-color" content="#0B7A75"><link rel="manifest" href="manifest.webmanifest">' +
  '<link rel="icon" href="icon-192.png"><link rel="apple-touch-icon" href="icon-192.png">' +
  '<meta name="apple-mobile-web-app-capable" content="yes"><meta name="mobile-web-app-capable" content="yes">' +
  '<meta name="apple-mobile-web-app-title" content="Траты"></head><body>'
$tail = '<script>if("serviceWorker" in navigator && location.protocol==="https:"){navigator.serviceWorker.register("sw.js").catch(function(){})}</script></body></html>'
[IO.File]::WriteAllText((Join-Path $site 'index.html'), $head + "`n" + $body + "`n" + $tail, $utf8)

# 2. иконки: сетка-«календарь» с подсветкой дней, как в приложении
Add-Type -AssemblyName System.Drawing
function New-Icon([int]$size, [string]$path) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.Clear([System.Drawing.Color]::FromArgb(255, 11, 122, 117))
  $alphas = @(70, 255, 120, 160, 70, 255, 255, 120, 70)
  $cell = $size * 0.16; $gap = $size * 0.045
  $start = ($size - (3 * $cell + 2 * $gap)) / 2
  $r = $cell * 0.28
  for ($i = 0; $i -lt 9; $i++) {
    $x = $start + ($i % 3) * ($cell + $gap); $y = $start + [math]::Floor($i / 3) * ($cell + $gap)
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc($x, $y, 2*$r, 2*$r, 180, 90); $p.AddArc($x+$cell-2*$r, $y, 2*$r, 2*$r, 270, 90)
    $p.AddArc($x+$cell-2*$r, $y+$cell-2*$r, 2*$r, 2*$r, 0, 90); $p.AddArc($x, $y+$cell-2*$r, 2*$r, 2*$r, 90, 90)
    $p.CloseFigure()
    $col = if ($i -eq 5) { [System.Drawing.Color]::FromArgb(255, 235, 104, 52) } else { [System.Drawing.Color]::FromArgb($alphas[$i], 255, 255, 255) }
    $g.FillPath((New-Object System.Drawing.SolidBrush $col), $p)
  }
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}
New-Icon 192 (Join-Path $site 'icon-192.png')
New-Icon 512 (Join-Path $site 'icon-512.png')

# 3. манифест
$manifest = @'
{
  "name": "Дневник трат",
  "short_name": "Траты",
  "description": "Учёт расходов и доходов: календарь, места с GPS, сводка и коэффициенты сбережений.",
  "lang": "ru",
  "start_url": "./",
  "scope": "./",
  "display": "standalone",
  "orientation": "portrait",
  "background_color": "#F2F5F4",
  "theme_color": "#0B7A75",
  "icons": [
    { "src": "icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
'@
[IO.File]::WriteAllText((Join-Path $site 'manifest.webmanifest'), $manifest, $utf8)

# 4. service worker: работа без интернета
$sw = @'
var CACHE = 'dnevnik-trat-v1';
var CORE = ['./', './index.html', './manifest.webmanifest', './icon-192.png', './icon-512.png'];
self.addEventListener('install', function (e) {
  e.waitUntil(caches.open(CACHE).then(function (c) { return c.addAll(CORE); }).then(function () { return self.skipWaiting(); }));
});
self.addEventListener('activate', function (e) {
  e.waitUntil(caches.keys().then(function (keys) {
    return Promise.all(keys.filter(function (k) { return k !== CACHE; }).map(function (k) { return caches.delete(k); }));
  }).then(function () { return self.clients.claim(); }));
});
self.addEventListener('fetch', function (e) {
  var req = e.request;
  if (req.method !== 'GET') return;
  var url = new URL(req.url);
  if (req.mode === 'navigate') {
    e.respondWith(fetch(req).then(function (res) {
      var copy = res.clone(); caches.open(CACHE).then(function (c) { c.put('./index.html', copy); }); return res;
    }).catch(function () { return caches.match('./index.html'); }));
    return;
  }
  if (url.origin === location.origin || /fonts\.(googleapis|gstatic)\.com$/.test(url.hostname)) {
    e.respondWith(caches.open(CACHE).then(function (c) {
      return c.match(req).then(function (hit) {
        var net = fetch(req).then(function (res) { if (res && (res.ok || res.type === 'opaque')) c.put(req, res.clone()); return res; });
        return hit || net;
      });
    }));
  }
});
'@
[IO.File]::WriteAllText((Join-Path $site 'sw.js'), $sw, $utf8)

Get-ChildItem $site | Select-Object Name, Length
