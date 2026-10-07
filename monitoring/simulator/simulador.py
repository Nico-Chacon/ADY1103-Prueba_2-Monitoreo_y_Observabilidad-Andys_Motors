"""
PLACEHOLDER - REEMPLAZAR por el script Python entregado por el docente (GitHub de la EP2).

Este archivo solo existe para que el stack levante de punta a punta (Prometheus
puede hacer scrape y el target aparece en estado UP) antes de copiar el script
real. NO genera las metricas de negocio de la evaluacion.

Pasos:
  1. Copiar el script del docente a esta carpeta (si se llama distinto, cambiar ENV SCRIPT en el Dockerfile).
  2. Agregar sus dependencias a requirements.txt.
  3. Verificar el puerto en que expone /metrics y alinearlo con prometheus.yml (target simulator:8000).
"""
import time
from prometheus_client import Gauge, start_http_server

PUERTO = 8000

placeholder = Gauge("simulador_placeholder", "1 mientras se ejecuta el placeholder (reemplazar por el script del docente)")
placeholder.set(1)

if __name__ == "__main__":
    start_http_server(PUERTO)
    print(f"[placeholder] Exponiendo /metrics en :{PUERTO}. Reemplazar por el script del docente.", flush=True)
    while True:
        time.sleep(60)
