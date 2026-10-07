const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const client = require('prom-client');

const SERVICE = 'create-contact';
const PORT = process.env.PORT || 3003;
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

const contactsCreated = new client.Counter({
  name: 'andysmotors_contactos_solicitados_total',
  help: 'Solicitudes de contacto registradas',
  labelNames: ['canal'],
});

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const CANALES = ['telefono', 'email', 'whatsapp'];

// Solicitud de contacto: el ejecutivo comercial la gestiona despues desde el CRM
app.post('/api/contacts', async (req, res) => {
  try {
    const { vehiculo_id, nombre, email, telefono, mensaje, canal_preferido } = req.body;
    if (!nombre || !email || !telefono)
      return res.status(400).json({ error: 'Campos obligatorios: nombre, email, telefono' });
    if (!EMAIL_RE.test(email)) return res.status(400).json({ error: 'El email no es valido' });
    const canal = canal_preferido || 'telefono';
    if (!CANALES.includes(canal)) return res.status(400).json({ error: 'canal_preferido debe ser telefono, email o whatsapp' });

    const conn = await mysql.createConnection(dbConfig);
    if (vehiculo_id) {
      const [veh] = await conn.execute('SELECT id FROM vehiculos WHERE id = ?', [vehiculo_id]);
      if (veh.length === 0) { await conn.end(); return res.status(404).json({ error: 'Vehiculo no encontrado' }); }
    }
    const [result] = await conn.execute(
      'INSERT INTO contactos (vehiculo_id, nombre, email, telefono, mensaje, canal_preferido) VALUES (?, ?, ?, ?, ?, ?)',
      [vehiculo_id || null, nombre, email, telefono, mensaje || null, canal]);
    const [nuevo] = await conn.execute('SELECT * FROM contactos WHERE id = ?', [result.insertId]);
    await conn.end();
    contactsCreated.inc({ canal });
    res.status(201).json(nuevo[0]);
  } catch (error) { fail(res, error, 'Error al registrar la solicitud de contacto'); }
});

app.listen(PORT, () => console.log(`[${SERVICE}] Puerto ${PORT}`));

