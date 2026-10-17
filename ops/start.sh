#!/bin/sh
set -eu
node /opt/hefesto/validate.cjs
# Se conserva el arranque nativo: exporta AUTH_URL, migra mediante DIRECT_DATABASE_URL y arranca Next.js.
exec /app/docker-start.sh
