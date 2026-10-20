#!/usr/bin/env bash
# Verifica que el compose principal cumple el contrato Coolify del MVP Hefesto:
#   1. Servicios sin profiles no exponen puertos ni rompen el sandbox.
#   2. Sin 'name:' fijo a nivel raíz, ni en redes o volúmenes.
# Además, para el perfil supabase-pg comprueba que DB_NAME y DB_SSLMODE
# llegan al servicio web (DSN parametrizable).
#
# Uso: bash scripts/coolify-check.sh

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

fail() { echo "ERROR: $*" >&2; exit 1; }
ok() { echo "  ok: $*"; }

# Extrae los nombres de variable ${VAR}, ${VAR:-default}, ${VAR:?msg}, etc.
detect_vars() {
    local file="$1"
    grep -oE '\$\{[A-Z_][A-Z0-9_]*(:[-?][^}]*)?\}' "$file" \
        | sed -E 's/^\$\{([A-Z_][A-Z0-9_]*).*/\1/' \
        | sort -u
}

# Valor ficticio no secreto para una variable detectada.
fictitious_value() {
    local v="$1"
    case "$v" in
        *HOST*) echo "host.ejemplo.invalid" ;;
        *URL*)  echo "https://ejemplo.invalid" ;;
        *EMAIL*) echo "usuario@ejemplo.invalid" ;;
        *)      echo "x1234567890abcdef" ;;
    esac
}

# Escribe un .env temporal con valores ficticios.
generate_env() {
    local compose="$1" out="$2" profile_type="$3"
    local vars
    vars=$(detect_vars "$compose")
    {
        echo "# Auto-generado por coolify-check.sh (valores ficticios)"
        for v in $vars; do
            echo "$v=$(fictitious_value "$v")"
        done
        if [ "$profile_type" = "supabase-pg" ]; then
            echo "DB_SSLMODE=disable"
            echo "DB_NAME=mvp_prueba"
        fi
    } > "$out"
}

COMPOSE="$ROOT/compose.yaml"
[ -f "$COMPOSE" ] || fail "No existe $COMPOSE"

ENV_FILE="$TMPDIR/.env"
generate_env "$COMPOSE" "$ENV_FILE" "supabase-pg"

echo "==> Renderizando $COMPOSE con .env ficticio"
RENDERED=$(docker compose --project-directory "$ROOT" \
    -f "$COMPOSE" --env-file "$ENV_FILE" config --format json) \
    || fail "docker compose config falló"

echo "==> Comprobando contrato"

# 2) Sin 'name:' fijo a nivel raíz. Compose siempre asigna uno por defecto
#    desde el directorio, así que comprobamos el YAML literal.
if grep -qE '^name:[[:space:]]' "$COMPOSE"; then
    fail "compose: 'name:' literal en el YAML; quitarlo (Coolify pone el nombre)"
fi
ok "compose sin name: literal"

# Lista de servicios sin profiles.
NO_PROFILE=$(echo "$RENDERED" | jq -r '
    .services | to_entries
    | map(select((.value.profiles // []) | length == 0))
    | map(.key) | join(" ")
')
[ -n "$NO_PROFILE" ] || fail "No hay servicios sin profiles"
echo "    servicios sin profiles: $NO_PROFILE"

for svc in $NO_PROFILE; do
    echo "  servicio '$svc'"

    # 1a) Sin 'ports' (Coolify enruta el dominio).
    PORTS=$(echo "$RENDERED" | jq --arg s "$svc" \
        '.services[$s].ports // [] | length')
    if [ "$PORTS" != "0" ]; then
        fail "$svc: $PORTS 'ports:'; quitarlos"
    fi
    ok "$svc sin ports"

    # 1b) Sin 'container_name'.
    CN=$(echo "$RENDERED" | jq -r --arg s "$svc" \
        '.services[$s].container_name // ""')
    if [ -n "$CN" ]; then
        fail "$svc: container_name=$CN; quitarlo"
    fi
    ok "$svc sin container_name"

    # 1c) Sin capacidades que rompan el sandbox.
    PRIV=$(echo "$RENDERED" | jq -r --arg s "$svc" \
        '.services[$s].privileged // false')
    if [ "$PRIV" = "true" ]; then
        fail "$svc: privileged=true; quitarlo"
    fi
    CAP=$(echo "$RENDERED" | jq --arg s "$svc" \
        '.services[$s].cap_add // [] | length')
    if [ "$CAP" != "0" ]; then
        fail "$svc: 'cap_add' con $CAP entradas; quitarlas"
    fi
    DEV=$(echo "$RENDERED" | jq --arg s "$svc" \
        '.services[$s].devices // [] | length')
    if [ "$DEV" != "0" ]; then
        fail "$svc: 'devices' con $DEV entradas; quitarlas"
    fi
    NM=$(echo "$RENDERED" | jq -r --arg s "$svc" \
        '.services[$s].network_mode // ""')
    if [ "$NM" = "host" ]; then
        fail "$svc: network_mode=host; quitarlo"
    fi
    PID=$(echo "$RENDERED" | jq -r --arg s "$svc" \
        '.services[$s].pid // ""')
    if [ "$PID" = "host" ]; then
        fail "$svc: pid=host; quitarlo"
    fi
    IPC=$(echo "$RENDERED" | jq -r --arg s "$svc" \
        '.services[$s].ipc // ""')
    if [ "$IPC" = "host" ]; then
        fail "$svc: ipc=host; quitarlo"
    fi
    SEC=$(echo "$RENDERED" | jq --arg s "$svc" \
        '.services[$s].security_opt // [] | map(select(test("unconfined"))) | length')
    if [ "$SEC" != "0" ]; then
        fail "$svc: security_opt=unconfined; quitarlo"
    fi
    ok "$svc sin privilegios de sandbox"

    # 1d) Sin binds prohibidos: docker.sock siempre vetado y ningún bind
    #    puede apuntar fuera del repo (los paths deben empezar por $ROOT/).
    BAD=$(echo "$RENDERED" | jq --arg s "$svc" --arg root "$ROOT" '
        .services[$s].volumes // []
        | map(select((.type // "") == "bind"))
        | map(select(
            ((.source // "") | startswith($root + "/") | not)
            or ((.source // "") | test("docker\\.sock"))
        ))
        | length')
    if [ "$BAD" != "0" ]; then
        fail "$svc: hay binds prohibidos (absolutos o docker.sock)"
    fi
    ok "$svc sin docker.sock"
done

# 2b) Redes sin 'name:' fijo en el YAML. Compose auto-asigna un name a
#     la red default, así que se inspecciona el YAML literal.
if awk '/^networks:[[:space:]]*\{?[[:space:]]*$/{f=1;next}
       /^volumes:[[:space:]]*\{?[[:space:]]*$|^services:[[:space:]]/{f=0}
       f' "$COMPOSE" | grep -qE '^[[:space:]]+name:[[:space:]]'; then
    fail "compose: red declarada con 'name:' en el YAML; quitarlo"
fi
ok "redes sin name: literal en YAML"

# 2c) Volúmenes sin 'name:' fijo en el YAML.
if awk '/^volumes:[[:space:]]*\{?[[:space:]]*$/{f=1;next}
       /^networks:[[:space:]]*\{?[[:space:]]*$|^services:[[:space:]]/{f=0}
       f' "$COMPOSE" | grep -qE '^[[:space:]]+name:[[:space:]]'; then
    fail "compose: volumen declarado con 'name:' en el YAML; quitarlo"
fi
ok "volúmenes sin name: literal en YAML"

# supabase-pg: DB_NAME=mvp_prueba y DB_SSLMODE=disable deben llegar al
# servicio web (DSN o variables). Coolify los recibe por .env y start.sh
# los usa para construir los DSN.
DB_NAME_VAL=$(echo "$RENDERED" | jq -r '.services.app.environment.DB_NAME // ""')
if [ "$DB_NAME_VAL" != "mvp_prueba" ]; then
    fail "supabase-pg: DB_NAME=$DB_NAME_VAL (esperado mvp_prueba) en servicio web"
fi
ok "DB_NAME=mvp_prueba presente en servicio web"

DB_SSLMODE_VAL=$(echo "$RENDERED" | jq -r '.services.app.environment.DB_SSLMODE // ""')
if [ "$DB_SSLMODE_VAL" != "disable" ]; then
    fail "supabase-pg: DB_SSLMODE=$DB_SSLMODE_VAL (esperado disable) en servicio web"
fi
ok "DB_SSLMODE=disable presente en servicio web"

# El DSN del servicio web se arma con DB_HOST/DB_PASSWORD; sin ellos
# start.sh aborta por 'parameter not set' antes de llegar a validate.cjs.
DB_HOST_VAL=$(echo "$RENDERED" | jq -r '.services.app.environment.DB_HOST // ""')
DB_PASSWORD_VAL=$(echo "$RENDERED" | jq -r '.services.app.environment.DB_PASSWORD // ""')
if [ -z "$DB_HOST_VAL" ]; then
    fail "supabase-pg: DB_HOST vacio en servicio web (start.sh aborta)"
fi
if [ -z "$DB_PASSWORD_VAL" ]; then
    fail "supabase-pg: DB_PASSWORD vacio en servicio web (start.sh aborta)"
fi
ok "DB_HOST y DB_PASSWORD presentes en servicio web"

echo "==> Todas las comprobaciones pasaron"