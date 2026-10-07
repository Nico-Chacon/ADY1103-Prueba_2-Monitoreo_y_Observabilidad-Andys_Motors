// Andys Motors - sitio publico
// Rutas relativas: Nginx enruta a cada microservicio (ver nginx.conf).
const API_VEHICLES = '/api/vehicles';
const API_VISITS = '/api/visits';
const API_CONTACTS = '/api/contacts';

let catalogo = [];

document.addEventListener('DOMContentLoaded', () => {
    cargarVehiculos();
    const d = new Date();
    d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
    document.getElementById('v-fecha').min = d.toISOString().slice(0, 16);
});

function esc(valor) {
    const d = document.createElement('div');
    d.textContent = valor === null || valor === undefined ? '' : String(valor);
    return d.innerHTML;
}
const clp = n => '$' + Number(n).toLocaleString('es-CL');

function mostrar(id, texto, tipo) {
    const el = document.getElementById(id);
    el.textContent = texto;
    el.className = 'mensaje ' + (tipo === 'exito' ? 'mensaje-exito' : 'mensaje-error');
    setTimeout(() => { el.textContent = ''; el.className = 'mensaje'; }, 6000);
}

async function pedir(url, opciones) {
    const resp = await fetch(url, opciones);
    const cuerpo = await resp.json().catch(() => ({}));
    if (!resp.ok) throw new Error(cuerpo.error || 'Error ' + resp.status);
    return cuerpo;
}

async function cargarVehiculos() {
    const params = new URLSearchParams();
    const q = document.getElementById('f-q').value.trim();
    const tipo = document.getElementById('f-tipo').value;
    if (q) params.append('q', q);
    if (tipo) params.append('tipo', tipo);
    try {
        catalogo = await pedir(API_VEHICLES + (params.toString() ? '?' + params : ''));
        renderizar();
    } catch (error) {
        document.getElementById('vehiculos-grid').innerHTML = '';
        document.getElementById('resumen').textContent = 'No se pudo cargar el catalogo: ' + error.message;
    }
}

function renderizar() {
    const grid = document.getElementById('vehiculos-grid');
    const elegido = document.getElementById('v-vehiculo').value;
    document.getElementById('resumen').textContent = catalogo.length + ' auto(s) encontrado(s)';
    grid.innerHTML = '';
    catalogo.forEach(v => {
        const div = document.createElement('div');
        div.className = 'card' + (String(v.id) === elegido ? ' elegido' : '');
        div.innerHTML = `
            <div><span class="badge ${esc(v.tipo)}">${esc(v.tipo)}</span><span class="badge ${esc(v.estado)}">${esc(v.estado)}</span></div>
            <h3>${esc(v.marca)} ${esc(v.modelo)} ${esc(v.anio)}</h3>
            <div class="precio">${clp(v.precio)}</div>
            <div class="datos">${esc(v.carroceria || '')} &middot; ${esc(v.combustible || '')} &middot; ${esc(v.transmision || '')}</div>
            <div class="datos">${v.tipo === 'usado' ? Number(v.kilometraje).toLocaleString('es-CL') + ' km' : '0 km'} &middot; Sucursal ${esc(v.sucursal)}</div>`;
        const btn = document.createElement('button');
        btn.textContent = 'Agendar visita';
        btn.disabled = v.estado !== 'disponible';
        btn.addEventListener('click', () => elegir(v));
        div.appendChild(btn);
        grid.appendChild(div);
    });
}

function elegir(v) {
    document.getElementById('v-vehiculo').value = v.id;
    document.getElementById('auto-elegido').textContent = `Auto elegido: ${v.marca} ${v.modelo} ${v.anio} (${v.sucursal})`;
    document.getElementById('btn-agendar').disabled = false;
    renderizar();
    document.getElementById('visita').scrollIntoView();
}

async function agendarVisita(event) {
    event.preventDefault();
    const datos = {
        vehiculo_id: parseInt(document.getElementById('v-vehiculo').value, 10),
        nombre_cliente: document.getElementById('v-nombre').value,
        email: document.getElementById('v-email').value,
        telefono: document.getElementById('v-telefono').value,
        fecha_visita: document.getElementById('v-fecha').value,
    };
    try {
        const visita = await pedir(API_VISITS, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(datos) });
        mostrar('msg-visita', `Visita agendada (N° ${visita.id}) en la sucursal ${visita.sucursal}. Te esperamos!`, 'exito');
        event.target.reset();
        document.getElementById('v-vehiculo').value = '';
        document.getElementById('auto-elegido').textContent = 'Elige un auto de la lista.';
        document.getElementById('btn-agendar').disabled = true;
        renderizar();
    } catch (error) { mostrar('msg-visita', 'Error: ' + error.message, 'error'); }
}

async function solicitarContacto(event) {
    event.preventDefault();
    const datos = {
        nombre: document.getElementById('c-nombre').value,
        email: document.getElementById('c-email').value,
        telefono: document.getElementById('c-telefono').value,
        mensaje: document.getElementById('c-mensaje').value,
    };
    try {
        await pedir(API_CONTACTS, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(datos) });
        mostrar('msg-contacto', 'Recibimos tus datos. Un ejecutivo te contactara pronto.', 'exito');
        event.target.reset();
    } catch (error) { mostrar('msg-contacto', 'Error: ' + error.message, 'error'); }
}
