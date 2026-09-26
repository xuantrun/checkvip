FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY api/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . /app

EXPOSE 5678

ENV PORT=5678
CMD ["python", "api/api_server.py"]
