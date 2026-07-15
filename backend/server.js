// Server Console Backend
// 单文件后端服务:JSON 文件持久化,无外部数据库依赖,便于一键部署。
// 默认仅绑定 127.0.0.1(内部使用);设置 MODE=external 且 HOST=0.0.0.0 可对外开放,
// 对外开放时写操作(POST)必须带 Authorization: Bearer <ADMIN_TOKEN>。

const fs = require('fs');
const path = require('path');
const express = require('express');
const cors = require('cors');

const PORT = process.env.PORT || 8787;
const HOST = process.env.HOST || '127.0.0.1';
const MODE = process.env.MODE || 'internal'; // internal | external
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || '';
const DATA_FILE = path.join(__dirname, 'data.json');

function loadData() {
  if (!fs.existsSync(DATA_FILE)) {
    const initial = { sites: [], models: [], posts: [], pipelines: [], domains: [], settings: { usageThreshold: 2 } };
    fs.writeFileSync(DATA_FILE, JSON.stringify(initial, null, 2));
    return initial;
  }
  try { return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8')); }
  catch (e) { return { sites: [], models: [], posts: [], pipelines: [], domains: [], settings: { usageThreshold: 2 } }; }
}
function saveData(data) { fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2)); }

let db = loadData();

const app = express();
app.use(cors());
app.use(express.json());

function requireAuth(req, res, next) {
  if (MODE !== 'external' || !ADMIN_TOKEN) return next(); // 内部模式默认放行
  const auth = req.headers.authorization || '';
  if (auth === 'Bearer ' + ADMIN_TOKEN) return next();
  return res.status(401).json({ error: '未授权 · 缺少或错误的 Authorization Bearer token' });
}

app.get('/api/health', (req, res) => {
  res.json({ ok: true, mode: MODE, time: new Date().toISOString() });
});

app.get('/api/overview', (req, res) => {
  res.json({
    siteCount: db.sites.length,
    modelCount: db.models.length,
    postCount: db.posts.length,
    pipelineCount: db.pipelines.length,
    domainCount: db.domains.length,
  });
});

function listRoute(key) {
  app.get('/api/' + key, (req, res) => res.json(db[key]));
  app.post('/api/' + key, requireAuth, (req, res) => {
    const item = req.body;
    if (!item || typeof item !== 'object') return res.status(400).json({ error: '请求体必须是 JSON 对象' });
    item.id = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
    item.createdAt = new Date().toISOString();
    db[key].push(item);
    saveData(db);
    res.json(item);
  });
  app.delete('/api/' + key + '/:id', requireAuth, (req, res) => {
    db[key] = db[key].filter(x => x.id !== req.params.id);
    saveData(db);
    res.json({ ok: true });
  });
}
['sites', 'models', 'posts', 'pipelines', 'domains'].forEach(listRoute);

app.get('/api/settings', (req, res) => res.json(db.settings));
app.post('/api/settings', requireAuth, (req, res) => {
  db.settings = { ...db.settings, ...req.body };
  saveData(db);
  res.json(db.settings);
});

app.get('/api/usage', (req, res) => {
  // 真实带宽遥测数据源占位:接入监控系统(如 vnstat / 云厂商监控 API)后在此返回真实序列。
  res.json({ series: [], note: '尚未接入带宽监控数据源' });
});

// 真实网络测速:下行 = 客户端计时读取本接口返回的随机字节；上行 = 客户端计时 POST 一段数据到本接口。
app.get('/api/speedtest/download', (req, res) => {
  const size = Math.min(parseInt(req.query.size) || 2000000, 20000000);
  const buf = Buffer.alloc(size);
  for (let i = 0; i < size; i += 4096) buf.writeUInt32LE((Math.random() * 0xffffffff) >>> 0, i);
  res.set('Content-Type', 'application/octet-stream');
  res.set('Cache-Control', 'no-store');
  res.send(buf);
});
app.post('/api/speedtest/upload', express.raw({ type: '*/*', limit: '50mb' }), (req, res) => {
  res.json({ ok: true, bytesReceived: req.body ? req.body.length : 0 });
});

app.listen(PORT, HOST, () => {
  console.log(`[server-console-backend] 运行中 · http://${HOST}:${PORT} · 模式: ${MODE}`);
});
