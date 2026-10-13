FROM python@sha256:e88e9763f943ec1834f992a4b51e0f24500486803e8bc534e5767af9ea65f6ce AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install curl for the health check.
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Create the non-root application account.
RUN groupadd --gid 10001 app && \
    useradd --uid 10001 --gid app --create-home app

WORKDIR /usr/local/app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && pip uninstall -y setuptools wheel

FROM base AS final

COPY . .

USER 10001:10001

EXPOSE 8080

CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:8080", "--log-file", "-", "--access-logfile", "-", "--workers", "2", "--keep-alive", "0"]
