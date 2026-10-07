FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
# Script a ejecutar: por defecto el del docente (simulador.py). Ajustar si se llama distinto.
ENV SCRIPT=simulador.py
# Puerto donde el script expone /metrics (debe coincidir con prometheus.yml)
EXPOSE 8000
CMD ["sh", "-c", "python -u $SCRIPT"]
