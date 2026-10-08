# AndysMotors — Infraestructura como código + Observabilidad

Infraestructura en AWS (Terraform + GitHub Actions) del sitio público de
**AndysMotors**, empresa de venta presencial de vehículos nuevos y usados
(sucursales Santiago Centro, Providencia, Las Condes y Maipú), más el stack de
observabilidad open source de la **EP2 (ADY1103 Monitoreo y Observabilidad)**:
Prometheus + Grafana en contenedores, alimentados por el script simulador del docente.

## Este repositorio parte de una base propia previa: 

- [Examen Final de Cloud (Base OG)](https://github.com/Nico-Chacon/ARY1101-EXAMEN-Cloud)
- [Prueba 1 Cloud - Freshbox App](https://github.com/Nico-Chacon/ARY1102-ARQUITECTURA_CLOUD-PRUEBA1.git)

## Diagrama de la infraestructura
![Diagrama](media/wip.gif)

Diagrama in progress (No creo q lo haga lol)

## El sitio web (qué hace y qué NO hace)

El sitio **no vende vehículos**: permite consultar el catálogo y la disponibilidad,
solicitar contacto y agendar visitas. La venta la concreta un ejecutivo en el CRM.

| Microservicio   | Puerto | Rutas (Nginx enruta por path/método)                               |
|-----------------|--------|---------------------------------------------------------------------|
| get-vehicles    | 3001   | `GET /api/vehicles` (filtros: tipo, marca, sucursal, estado, precio_max, q), `GET /api/vehicles/:id` |
| create-visit    | 3002   | `POST /api/visits` — agenda visita (09:00–19:00, fecha futura, vehículo disponible, sin doble reserva) |
| create-contact  | 3003   | `POST /api/contacts` — solicitud de contacto (teléfono / email / WhatsApp) |
| manage-visits   | 3004   | `GET /api/visits?email=` y `DELETE /api/visits/:id?email=` (cancelar) (API; sin pantalla en el sitio básico) |

Base de datos `andysmotors` (MySQL/MariaDB en EC2 dedicada): `vehiculos`, `visitas`, `contactos` (`app/db/init.sql`).

Cada microservicio expone `/health` y `/metrics` (prom-client): `andysmotors_http_requests_total`,
`andysmotors_http_request_duration_seconds`, `andysmotors_db_errors_total`, y métricas de negocio
(`andysmotors_visitas_agendadas_total`, `andysmotors_visitas_rechazadas_total{motivo}`,
`andysmotors_contactos_solicitados_total{canal}`, `andysmotors_visitas_canceladas_total`,
`andysmotors_vehiculos_stock{estado,tipo}`).

## Flujo de tráfico

```
Internet → ALB (:80) → EC2 App (Nginx :80)
                          ├── /api/vehicles        → get-vehicles:3001
                          ├── POST /api/visits     → create-visit:3002
                          ├── GET|DELETE /api/visits → manage-visits:3004
                          └── /api/contacts        → create-contact:3003
                                          ↓
                                EC2 MySQL (:3306, capa Data)

EC2 Observabilidad (subred pública, Elastic IP)
   ├── Prometheus :9090 ── scrape ──► simulator:8000 (script del docente)
   │                    └─ scrape ──► microservicios :3001-3004 (ec2_sd_configs, SG restringido)
   └── Grafana    :3000 ── datasource aprovisionado → Prometheus
```

## Módulos Terraform

| Módulo        | Descripción |
|---------------|-------------|
| networking    | VPC /22 de 3 capas, 2 NAT GW |
| security      | SG por capa (ALB → App → Data) + SG de observabilidad (9090/3000) y acceso a `/metrics` solo desde ese SG |
| ecr           | 6 repositorios: frontend, get-vehicles, create-visit, create-contact, manage-visits, **simulator** |
| database      | EC2 t4g.small + MySQL, EBS cifrado |
| loadbalancer  | ALB + Target Group (:80) |
| compute       | ASG (min 2 / máx 4) con los 5 contenedores vía Docker Compose |
| **observability** | **EC2 + Elastic IP con Docker Compose: Prometheus, Grafana y simulador (EP2)** |
| backup        | AWS Backup diario (LabRole) |
| monitoring    | CloudWatch Alarms + SNS + Dashboard |
| budgets       | AWS Budgets 60/80/100 % |
| cloudtrail    | (deshabilitado en `main.tf` por restricciones de Academy) |

## Estructura

```
.
├── app/                         # Sitio web AndysMotors
│   ├── frontend/                # Nginx + HTML/CSS/JS
│   ├── backend/{get-vehicles,create-visit,create-contact,manage-visits}/
│   ├── db/init.sql
│   └── build-and-push.sh        # Build + push de las 6 imágenes a ECR
├── monitoring/                  # EP2
│   ├── prometheus/prometheus.yml            # ← archivo a entregar como adjunto
│   ├── grafana/provisioning/datasources/prometheus.yml
│   └── simulator/               # ← copiar aquí el script del docente
├── environments/dev/            # Orquestación Terraform
├── modules/                     # Módulos
├── scripts/                     # user-data: app, db, obs
└── .github/workflows/           # plan, apply, destroy
```

## Despliegue con GitHub Actions

1. Crear **una vez** el bucket del estado: `aws s3api create-bucket --bucket andysmotors-tfstate --region us-east-1`
   (y el Key Pair `andysmotors-key`, o cambiar `key_name` en `variables.tf`).
2. Secrets del repositorio: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`
   (se renuevan en cada sesión del Learner Lab), `EMAIL_SNS`, `DB_ROOT_PASSWORD`, `DB_PASSWORD`,
   `OWNER_NAME`, `BACKUP_IAM_ROLE_ARN` y **`GRAFANA_ADMIN_PASSWORD`** (nuevo; alfanumérica, mín. 8 caracteres).
3. Push a `main` (cambios en `*.tf`, `app/**`, `monitoring/**` o `scripts/**`) o ejecución manual de **Terraform Apply**.
   El pipeline crea los ECR → construye y sube las 6 imágenes → aplica el resto.
4. Las URLs aparecen en los *outputs* del job: `alb_dns_name`, `prometheus_url`, `grafana_url` (usuario `admin`).

Si cambia el script en `monitoring/simulator/`, Terraform detecta el cambio (hash) y recrea la EC2 de observabilidad para bajar la imagen nueva.

## Entregables EP2 que salen de este repo

- `monitoring/prometheus/prometheus.yml` (adjunto independiente; es el mismo archivo que se monta en el contenedor).
- Capturas: `docker ps` en la EC2 de observabilidad (vía SSM), Prometheus *Status → Targets*, Grafana *Connections → Data sources → Save & test*.

## Tagging

| Tag         | Valor                   |
|-------------|-------------------------|
| Project     | andysmotors      |
| Environment | dev                     |
| Owner       | AndysMotors             |
| CostCenter  | andysmotors-automotriz  |
| ManagedBy   | terraform               |
