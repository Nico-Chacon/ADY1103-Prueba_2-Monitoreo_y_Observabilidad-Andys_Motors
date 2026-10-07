const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const client = require('prom-client');

const SERVICE = 'create-visit';
const PORT = process.env.PORT || 3002;
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

const visitsCreated = new client.Counter({
  name: 'andysmotors_visitas_agendadas_total',
  help: 'Visitas agendadas correctamente',
  labelNames: ['sucursal'],
});
const visitsRejected = new client.Counter({
  name: 'andysmotors_visitas_rechazadas_total',
  help: 'Intentos de agendamiento rechazados por validacion de negocio',
  labelNames: ['motivo'],
});

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const FECHA_RE = /^(\d{4}-\d{2}-\d{2})[T ](\d{2}):(\d{2})/;

// Fecha/hora actual en Chile con formato 'YYYY-MM-DDTHH:mm' (para comparar como texto)
function ahoraChile() {
  return new Date().toLocaleString('sv-SE', { timeZone: 'America/Santiago' }).replace(' ', 'T').slice(0, 16);
}

function rechazar(res, status, motivo, mensaje) {
  visitsRejected.inc({ motivo });
  return res.status(status).json({ error: mensaje });
}

// Agendar visita a una sucursal para ver un vehiculo (horario comercial 09:00 - 19:00)
app.post('/api/visits', async (req, res) => {
  try {
    const { vehiculo_id, nombre_cliente, email, telefono, fecha_visita } = req.body;
    if (!vehiculo_id || !nombre_cliente || !email || !telefono || !fecha_visita)
      return rechazar(res, 400, 'campos_faltantes', 'Campos obligatorios: vehiculo_id, nombre_cliente, email, telefono, fecha_visita');
    if (!EMAIL_RE.test(email)) return rechazar(res, 400, 'email_invalido', 'El email no es valido');
    const m = FECHA_RE.exec(fecha_visita);
    if (!m) return rechazar(res, 400, 'fecha_invalida', 'Formato de fecha invalido (use AAAA-MM-DDTHH:mm)');
    const hora = Number(m[2]);
    if (hora < 9 || hora >= 19) return rechazar(res, 400, 'fuera_de_horario', 'Las visitas se agendan entre las 09:00 y las 19:00');
    const fechaTxt = `${m[1]}T${m[2]}:${m[3]}`;
    if (fechaTxt <= ahoraChile()) return rechazar(res, 400, 'fecha_pasada', 'La fecha de la visita debe ser futura');

    const conn = await mysql.createConnection(dbConfig);
    const [veh] = await conn.execute('SELECT id, sucursal, estado FROM vehiculos WHERE id = ?', [vehiculo_id]);
    if (veh.length === 0) { await conn.end(); return rechazar(res, 404, 'vehiculo_inexistente', 'Vehiculo no encontrado'); }
    if (veh[0].estado !== 'disponible') { await conn.end(); return rechazar(res, 409, 'vehiculo_no_disponible', 'El vehiculo no esta disponible para visitas'); }

    const fechaSql = `${m[1]} ${m[2]}:${m[3]}:00`;
    const [dup] = await conn.execute("SELECT id FROM visitas WHERE vehiculo_id = ? AND fecha_visita = ? AND estado = 'agendada'", [vehiculo_id, fechaSql]);
    if (dup.length > 0) { await conn.end(); return rechazar(res, 409, 'horario_ocupado', 'Ese horario ya esta tomado para este vehiculo'); }

    const [result] = await conn.execute(
      'INSERT INTO visitas (vehiculo_id, nombre_cliente, email, telefono, sucursal, fecha_visita) VALUES (?, ?, ?, ?, ?, ?)',
      [vehiculo_id, nombre_cliente, email, telefono, veh[0].sucursal, fechaSql]);
    const [nueva] = await conn.execute('SELECT * FROM visitas WHERE id = ?', [result.insertId]);
    await conn.end();
    visitsCreated.inc({ sucursal: veh[0].sucursal });
    res.status(201).json(nueva[0]);
  } catch (error) { fail(res, error, 'Error al agendar la visita'); }
});

app.listen(PORT, () => console.log(`[${SERVICE}] Puerto ${PORT}`));

