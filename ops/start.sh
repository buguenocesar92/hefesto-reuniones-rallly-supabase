#!/bin/sh
set -eu
# Construye DSNs parametrizados según DB_SSLMODE y los exporta antes del
# arranque nativo (que usa DIRECT_DATABASE_URL para Prisma y DATABASE_URL
# para el driver Node pg). Por defecto mantiene sslmode=verify-full con CA.
SSL_PG=""
SSL_PRISMA=""
if [ "${DB_SSLMODE:-verify-full}" = "verify-full" ]; then
    SSL_PG="&sslrootcert=${DB_SSLROOTCERT:-/certs/ca.crt}"
    SSL_PRISMA="&sslcert=${DB_SSLCERT:-/certs/ca.crt}"
fi
: "${DATABASE_URL:=postgresql://${DB_USER:-rallly_app}:${DB_PASSWORD}@${DB_HOST}:5432/${DB_NAME:-postgres}?sslmode=${DB_SSLMODE:-verify-full}${SSL_PG}}"
if [ "${DB_SSLMODE:-verify-full}" = "verify-full" ]; then
    : "${DIRECT_DATABASE_URL:=postgresql://${DB_USER:-rallly_app}:${DB_PASSWORD}@${DB_HOST}:5432/${DB_NAME:-postgres}?schema=public&sslmode=require&sslaccept=strict${SSL_PRISMA}}"
else
    : "${DIRECT_DATABASE_URL:=postgresql://${DB_USER:-rallly_app}:${DB_PASSWORD}@${DB_HOST}:5432/${DB_NAME:-postgres}?schema=public&sslmode=${DB_SSLMODE:-disable}}"
fi
export DATABASE_URL DIRECT_DATABASE_URL
node /opt/hefesto/validate.cjs
# Se conserva el arranque nativo: exporta AUTH_URL, migra mediante DIRECT_DATABASE_URL y arranca Next.js.
exec /app/docker-start.sh