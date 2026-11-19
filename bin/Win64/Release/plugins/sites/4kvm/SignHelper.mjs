// 4kvm.org 播放签名助手：调用站点自带的 WASM 计算 /video/play 签名 URL
// 用法: node SignHelper.mjs <dataid> <secret> <quality> <playKey> <glue.mjs> <wasm.bin> <out.txt>
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';

const [, , dataid, secret, quality, playKey, jsPath, wasmPath, outPath] = process.argv;

try {
  const mod = await import(pathToFileURL(jsPath).href);
  const bytes = fs.readFileSync(wasmPath);
  if (typeof mod.initSync === 'function') {
    mod.initSync(bytes);
  } else if (typeof mod.default === 'function') {
    await mod.default({ module_or_path: bytes });
  } else {
    throw new Error('WASM glue 缺少 initSync/default 初始化函数');
  }
  const url = mod.build_play_url(dataid, secret, quality, playKey);
  fs.writeFileSync(outPath, url, 'utf8');
} catch (e) {
  fs.writeFileSync(outPath, 'ERROR: ' + (e && e.stack ? e.stack : String(e)), 'utf8');
  process.exitCode = 1;
}
