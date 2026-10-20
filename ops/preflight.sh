#!/bin/sh
set -eu
[ "$SUPABASE_DEDICATED_CONFIRMED" = true ] || { echo 'Confirmar proyecto exclusivo'; exit 1; }
[ "$SUPABASE_DATA_API_DISABLED" = true ] || { echo 'Desactivar Data API y confirmar'; exit 1; }
# La CA es obligatoria solo cuando sslmode=verify-full.
if [ "${PGSSLMODE:-verify-full}" = "verify-full" ]; then
    [ -s "$PGSSLROOTCERT" ] || { echo 'Falta CA DB'; exit 1; }
fi
psql --no-psqlrc -v ON_ERROR_STOP=1 -f /opt/hefesto/preflight.sql
if [ "${BOOTSTRAP_MODE:-false}" != true ]; then
 psql --no-psqlrc -v ON_ERROR_STOP=1 -v admin_email="$INITIAL_ADMIN_EMAIL" -f /opt/hefesto/production.sql
fi