const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const client = require('prom-client');

const SERVICE = 'get-vehicles';
const PORT = process.env.PORT || 3001;
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'alumno',
  password: process.env.DB_PASS || 'alumno123',
  database: process.env.DB_NAME || 'andysmotors',
  port: process.env.DB_PORT || 3306,
};

const app = express();
app.use(cors());
app.use(express.json());

// ---------- Observabilidad (EP2): metricas Prometheus ----------
client.register.setDefaultLabels({ service: SERVICE });
client.collectDefaultMetrics();
const httpRequests = new client.Counter({
  name: 'andysmotors_http_requests_total',
  help: 'Total de peticiones HTTP recibidas',
  labelNames: ['method', 'route', 'status'],
});
const httpDuration = new client.Histogram({
  name: 'andysmotors_http_request_duration_seconds',
  help: 'Latencia de las peticiones HTTP en segundos',
  labelNames: ['method', 'route'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
});
const dbErrors = new client.Counter({
  name: 'andysmotors_db_errors_total',
  help: 'Errores de acceso a la base de datos',
});
app.use((req, res, next) => {
  if (req.path === '/metrics') return next();
  const end = httpDuration.startTimer();
  res.on('finish', () => {
    const route = req.route ? req.route.path : 'unmatched';
    httpRequests.inc({ method: req.method, route, status: res.statusCode });
    end({ method: req.method, route });
  });
  next();
});
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});
app.get('/health', (req, res) => res.json({ status: 'OK', service: SERVICE, port: PORT }));

function fail(res, error, mensaje) {
  dbErrors.inc();
  console.error('[' + SERVICE + ']', error.message);
  return res.status(500).json({ error: mensaje, detalle: error.message });
}

// Stock actual por estado y tipo (se consulta en cada scrape de Prometheus)
new client.Gauge({
  name: 'andysmotors_vehiculos_stock',
  help: 'Cantidad de vehiculos en el catalogo por estado y tipo',
  labelNames: ['estado', 'tipo'],
  async collect() {
    try {
      const conn = await mysql.createConnection(dbConfig);
      const [rows] = await conn.execute('SELECT estado, tipo, COUNT(*) AS total FROM vehiculos GROUP BY estado, tipo');
      await conn.end();
      this.reset();
      rows.forEach(r => this.set({ estado: r.estado, tipo: r.tipo }, Number(r.total)));
    } catch (error) { dbErrors.inc(); }
  },
});

// Catalogo con filtros opcionales: tipo, marca, sucursal, estado, precio_max, q (texto libre)
app.get('/api/vehicles', async (req, res) => {
  try {
    const { tipo, marca, sucursal, estado, precio_max, q } = req.query;
    const where = [];
    const params = [];
    if (tipo)       { where.push('tipo = ?');       params.push(tipo); }
    if (marca)      { where.push('marca = ?');      params.push(marca); }
    if (sucursal)   { where.push('sucursal = ?');   params.push(sucursal); }
    if (estado)     { where.push('estado = ?');     params.push(estado); }
    if (precio_max) { where.push('precio <= ?');    params.push(Number(precio_max)); }
    if (q)          { where.push('(marca LIKE ? OR modelo LIKE ?)'); params.push(`%${q}%`, `%${q}%`); }
    const sql = 'SELECT * FROM vehiculos' + (where.length ? ' WHERE ' + where.join(' AND ') : '') + ' ORDER BY tipo, marca, modelo';
    const conn = await mysql.createConnection(dbConfig);
    const [rows] = await conn.execute(sql, params);
    await conn.end();
    res.json(rows);
  } catch (error) { fail(res, error, 'Error al consultar vehiculos'); }
});

app.get('/api/vehicles/:id', async (req, res) => {
  try {
    const conn = await mysql.createConnection(dbConfig);
    const [rows] = await conn.execute('SELECT * FROM vehiculos WHERE id = ?', [req.params.id]);
    await conn.end();
    if (rows.length === 0) return res.status(404).json({ error: 'Vehiculo no encontrado' });
    res.json(rows[0]);
  } catch (error) { fail(res, error, 'Error al consultar el vehiculo'); }
});

app.listen(PORT, () => console.log(`[${SERVICE}] Puerto ${PORT}`));

