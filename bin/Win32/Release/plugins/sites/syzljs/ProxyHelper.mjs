// 追剧网(syzljs.cn) 本地分片代理
// 与 4kvm 版的区别：
//   1) 支持递归展开多级 m3u8：master(#EXT-X-STREAM-INF) -> media -> .ts
//   2) 子列表与分片下载带 Referer（本站 CDN 兼容，直连亦可）
//   3) 分片直连即可(HTTP200/TS同步字节0x47/无加密)，智能分流：直连优先失败走代理
//
// 智能分流：每个请求先直连（短超时），失败再走系统代理；代理未开时国内 CDN 直连可播。
//
// 用法: node ProxyHelper.mjs <source.m3u8> <port> <原始m3u8完整URL> [readyFile] [logDir]

import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const [, , srcFile, portArg, baseUrl, readyArg, logDirArg] = process.argv;
const PORT_REQUESTED = parseInt(portArg || '0', 10);
const LOG_DIR = logDirArg || path.dirname(process.argv[1] || '.');
const LOG_FILE = path.join(LOG_DIR, 'proxy.log');
const READY_FILE = readyArg || path.join(LOG_DIR, 'proxy_ready.txt');
const PROXY_USED_FILE = path.join(LOG_DIR, 'proxy_used.txt');
function markProxyUsed() {
  try { fs.writeFileSync(PROXY_USED_FILE, '1', 'utf8'); } catch { /* ignore */ }
}
try { fs.unlinkSync(PROXY_USED_FILE); } catch { /* ignore */ }

try { fs.mkdirSync(LOG_DIR, { recursive: true }); } catch { /* ignore */ }

function log(msg) {
  try {
    const t = new Date().toISOString();
    fs.appendFileSync(LOG_FILE, '[' + t + '][pid ' + process.pid + '] ' + msg + '\n', 'utf8');
  } catch { /* ignore */ }
}
process.on('uncaughtException', (e) => log('UNCAUGHT: ' + (e && e.stack ? e.stack : String(e))));
process.on('unhandledRejection', (e) => log('UNHANDLED: ' + String(e)));

// ---- 探测系统代理（注册表 WinINET 优先） ----
function detectProxy() {
  try {
    const out = execFileSync('powershell.exe', [
      '-NoProfile', '-Command',
      "(Get-ItemProperty 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings' -ErrorAction SilentlyContinue).ProxyServer",
    ], { encoding: 'utf8', timeout: 8000 });
    const v = out.trim();
    if (v) return /^https?:\/\//i.test(v) ? v : 'http://' + v;
  } catch { /* ignore */ }
  for (const k of ['HTTPS_PROXY', 'https_proxy', 'HTTP_PROXY', 'http_proxy']) {
    if (process.env[k]) return process.env[k];
  }
  return '';
}
let PROXY = detectProxy();
if (PROXY) {
  try {
    const u = new URL(PROXY);
    const net = await import('node:net');
    const ok = await new Promise((resolve) => {
      const s = net.connect({ host: u.hostname, port: parseInt(u.port, 10) || 80 });
      const done = (v) => { try { s.destroy(); } catch {} resolve(v); };
      s.setTimeout(1500);
      s.on('connect', () => done(true));
      s.on('timeout', () => done(false));
      s.on('error', () => done(false));
    });
    if (!ok) { log('PROXY DOWN, fallback direct: ' + PROXY); PROXY = ''; }
  } catch { PROXY = ''; }
}
log('DETECT PROXY=' + (PROXY || '(none, direct)'));

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
           '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';
// 本站 CDN 需要 Referer：用 m3u8 源地址的 origin
let REFERER = '';
try { const u = new URL(baseUrl); REFERER = u.protocol + '//' + u.host + '/'; } catch {}
log('REFERER=' + (REFERER || '(none)'));

const PNG_MAGIC = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const PNG_IEND = Buffer.from([0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82]);
function stripFakePng(buf) {
  if (buf.length < 16 || !buf.subarray(0, 8).equals(PNG_MAGIC)) return { data: buf, stripped: 0 };
  const idx = buf.indexOf(PNG_IEND);
  const headerEnd = idx >= 0 ? idx + PNG_IEND.length : 0;
  if (headerEnd > 0 && headerEnd < buf.length - 188) return { data: buf.subarray(headerEnd), stripped: headerEnd };
  return { data: buf, stripped: 0 };
}

function b64urlEncode(buf) {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
function b64urlDecode(s) {
  let t = s.replace(/-/g, '+').replace(/_/g, '/');
  while (t.length % 4) t += '=';
  return Buffer.from(t, 'base64');
}
function absUrl(u, base) {
  if (/^https?:\/\//i.test(u)) return u;
  if (u.startsWith('//')) return 'https:' + u;
  try { return new URL(u, base || baseUrl).href; } catch { return u; }
}

// 把 #EXT-X-KEY 的 URI 改写成代理本地 /key/ 路由（若该站出现 AES 加密流）
function rewriteKeyUri(tag, currentUrl) {
  return tag.replace(/(URI\s*=\s*)(["'])([^"']+)\2/i, (m, p1, q, uri) => {
    const abs = absUrl(uri, currentUrl);
    return p1 + q + '/key/' + b64urlEncode(Buffer.from(abs, 'utf8')) + q;
  });
}

// 智能下载：直连优先（短超时，不耗代理流量），失败走系统代理
function curlFetch(url, isText) {
  const base = ['-sS', '-m', '25', '-A', UA];
  if (REFERER) base.push('-e', REFERER);
  const opts = { maxBuffer: 64 * 1024 * 1024, timeout: 28000 };
  if (isText) opts.encoding = 'utf8';
  try {
    return execFileSync('curl.exe', [...base, '--noproxy', '*', '--connect-timeout', '5', url], opts);
  } catch (directErr) {
    if (!PROXY) throw directErr;
    log('DIRECT FAIL, retry via proxy: ' + url);
    markProxyUsed();
    return execFileSync('curl.exe', [...base, '-x', PROXY, url], opts);
  }
}

// 递归展开播放列表：master(#EXT-X-STREAM-INF) -> media -> .ts
// 返回已改写的行数组（子 m3u8 就地展开，分片改为本地 /seg/ 路径）
function expandPlaylist(text, currentUrl, depth) {
  if (depth > 6) { log('EXPAND DEPTH LIMIT at ' + currentUrl); return []; }
  const lines = String(text).split(/\r?\n/);
  const out = [];
  let pendingTags = [];
  for (const raw of lines) {
    const line = raw.trim();
    if (!line) continue;
    if (line.startsWith('#')) {
      if (/^#EXT-X-KEY\b/i.test(line)) pendingTags.push(rewriteKeyUri(line, currentUrl));
      else pendingTags.push(line);
      continue;
    }
    const u = absUrl(line, currentUrl);
    // 子播放列表：URL 指向 .m3u8（master 里的 #EXT-X-STREAM-INF 已进 pendingTags，丢弃）
    if (/\.m3u8(\?|$)/i.test(u)) {
      pendingTags = [];
      log('EXPAND SUB: ' + u);
      let sub;
      try { sub = curlFetch(u, true); }
      catch (e) { log('SUB FETCH FAIL: ' + String((e && e.message) || e) + ' ' + u); continue; }
      out.push(...expandPlaylist(sub, u, depth + 1));
      continue;
    }
    // 防抓取诱饵
    if (line.includes('/ets/')) { pendingTags = []; continue; }
    out.push(...pendingTags);
    pendingTags = [];
    out.push('/seg/' + b64urlEncode(Buffer.from(u, 'utf8')) + '.ts');
  }
  out.push(...pendingTags);
  return out;
}

// 获取主播放列表：优先用 curl 直取 baseUrl（证书由 curl 用系统 CA 校验，
// 避免 VLC 因个别 CDN 证书域名不匹配弹窗）；失败再用本地已下载的 srcFile。
let masterSrc = '';
function getMaster() {
  if (masterSrc) return masterSrc;
  try {
    const t = curlFetch(baseUrl, true);
    if (t && t.indexOf('#EXTM3U') >= 0) {
      masterSrc = t;
      log('MASTER via curl len=' + t.length);
      return masterSrc;
    }
  } catch (e) { log('MASTER curl FAIL: ' + String((e && e.message) || e)); }
  try { masterSrc = fs.readFileSync(srcFile, 'utf8'); log('MASTER via srcFile len=' + masterSrc.length); }
  catch (e) { log('READ PLAYLIST FAIL: ' + String(e)); masterSrc = ''; }
  return masterSrc;
}

let headLogged = false;
function buildPlaylist() {
  const src = getMaster();
  if (!src) return '';
  if (!headLogged) {
    headLogged = true;
    log('M3U8 HEAD: ' + src.split(/\r?\n/).filter((x) => x.trim()).slice(0, 14).join(' | '));
  }
  const lines = expandPlaylist(src, baseUrl, 0);
  log('BUILD PLAYLIST: ' + lines.length + ' lines');
  return lines.join('\n') + '\n';
}

const server = http.createServer((req, res) => {
  const reqPath = req.url || '/';
  res.setHeader('Access-Control-Allow-Origin', '*');
  if (reqPath === '/ping') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('ok');
    return;
  }
  if (reqPath === '/index.m3u8' || reqPath === '/') {
    res.writeHead(200, { 'Content-Type': 'application/vnd.apple.mpegurl' });
    res.end(buildPlaylist() || '#EXTM3U\n#EXT-X-ENDLIST\n');
    return;
  }
  let m = /^\/seg\/([A-Za-z0-9_-]+)\.ts$/.exec(reqPath);
  if (m) {
    const url = b64urlDecode(m[1]).toString('utf8');
    try {
      const raw = curlFetch(url, false);
      const { data: buf, stripped } = stripFakePng(raw);
      res.writeHead(200, {
        'Content-Type': 'video/mp2t',
        'Content-Length': buf.length,
        'X-Stripped-Header': String(stripped),
      });
      res.end(buf);
    } catch (e) {
      log('SEG FAIL ' + String((e && e.message) || e) + ' ' + url);
      res.writeHead(502, { 'Content-Type': 'text/plain' });
      res.end(String((e && e.message) || e));
    }
    return;
  }
  m = /^\/key\/([A-Za-z0-9_-]+)$/.exec(reqPath);
  if (m) {
    const url = b64urlDecode(m[1]).toString('utf8');
    try {
      const buf = curlFetch(url, false);
      res.writeHead(200, { 'Content-Type': 'application/octet-stream', 'Content-Length': buf.length });
      res.end(buf);
    } catch (e) {
      log('KEY FAIL ' + String((e && e.message) || e) + ' ' + url);
      res.writeHead(502, { 'Content-Type': 'text/plain' });
      res.end(String((e && e.message) || e));
    }
    return;
  }
  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('not found');
});

server.listen(PORT_REQUESTED, '127.0.0.1', () => {
  const actualPort = server.address().port;
  log('START src=' + srcFile + ' port=' + actualPort + ' base=' + baseUrl);
  try { fs.writeFileSync(READY_FILE, String(actualPort), 'utf8'); }
  catch (e) { log('WRITE READY FAIL: ' + String(e)); }
  process.stdout.write('READY ' + actualPort + '\n');
});
