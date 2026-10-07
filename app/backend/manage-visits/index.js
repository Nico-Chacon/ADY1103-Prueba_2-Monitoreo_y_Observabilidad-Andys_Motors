const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const client = require('prom-client');

const SERVICE = 'manage-visits';
const PORT = process.env.PORT || 3004;
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

const visitsCancelled = new client.Counter({
  name: 'andysmotors_visitas_canceladas_total',
  help: 'Visitas canceladas por el cliente',
});

// Consultar las visitas de un cliente (se identifica por su email)
app.get('/api/visits', async (req, res) => {
  try {
    const { email } = req.query;
    if (!email) return res.status(400).json({ error: 'Debe indicar el email del cliente (?email=...)' });
    const conn = await mysql.createConnection(dbConfig);
    const [rows] = await conn.execute(
      `SELECT v.id, v.fecha_visita, v.estado, v.sucursal, ve.marca, ve.modelo, ve.anio
         FROM visitas v JOIN vehiculos ve ON ve.id = v.vehiculo_id
        WHERE v.email = ? ORDER BY v.fecha_visita DESC`, [email]);
    await conn.end();
    res.json(rows);
  } catch (error) { fail(res, error, 'Error al consultar las visitas'); }
});

// Cancelar una visita agendada (requiere el email con el que se agendo)
app.delete('/api/visits/:id', async (req, res) => {
  try {
    const { email } = req.query;
    if (!email) return res.status(400).json({ error: 'Debe indicar el email del cliente (?email=...)' });
    const conn = await mysql.createConnection(dbConfig);
    const [rows] = await conn.execute("SELECT id FROM visitas WHERE id = ? AND email = ? AND estado = 'agendada'", [req.params.id, email]);
    if (rows.length === 0) { await conn.end(); return res.status(404).json({ error: 'Visita agendada no encontrada para ese email' }); }
    await conn.execute("UPDATE visitas SET estado = 'cancelada' WHERE id = ?", [req.params.id]);
    await conn.end();
    visitsCancelled.inc();
    res.json({ message: 'Visita cancelada correctamente', id: parseInt(req.params.id, 10) });
  } catch (error) { fail(res, error, 'Error al cancelar la visita'); }
});

app.listen(PORT, () => console.log(`[${SERVICE}] Puerto ${PORT}`));

