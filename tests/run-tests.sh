#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

[ -f ".env" ] && source .env

POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
TEST_DB="_test_db"
COMPOSE_CMD="docker compose"
command -v docker compose &>/dev/null || COMPOSE_CMD="docker-compose"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASSED=0
FAILED=0

pass() { echo -e "${GREEN}✓ $1${NC}"; PASSED=$((PASSED + 1)); }
fail() { echo -e "${RED}✗ $1${NC}"; FAILED=$((FAILED + 1)); }

run_psql() {
    docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" postgres_server \
        psql -h localhost -U "$POSTGRES_USER" -d "$1" -t -A -c "$2" 2>/dev/null
}

run_db_utils() {
    $COMPOSE_CMD --profile tools run --rm -T db_utils "$*" 2>&1
}

cleanup() {
    echo ""
    echo "Limpiando..."
    run_psql postgres "DROP DATABASE IF EXISTS \"$TEST_DB\";" >/dev/null 2>&1 || true
    rm -f "$PROJECT_DIR/backups/${TEST_DB}_backup_"*.sql.gz 2>/dev/null || true
}
trap cleanup EXIT

echo "================================"
echo "  DataManager Tests"
echo "================================"
echo ""

echo "--- Verificando entorno ---"
docker info &>/dev/null && pass "Docker corriendo" || fail "Docker no disponible"
docker ps -q -f "name=postgres_server" | grep -q . && pass "PostgreSQL corriendo" || fail "PostgreSQL no corriendo"

echo ""
echo "--- Conectividad ---"
run_psql postgres "SELECT 1;" | grep -q 1 && pass "Conexión PostgreSQL" || fail "Conexión PostgreSQL"

echo ""
echo "--- Test Backup/Restore ---"

run_psql postgres "DROP DATABASE IF EXISTS \"$TEST_DB\";" >/dev/null
run_psql postgres "CREATE DATABASE \"$TEST_DB\";" >/dev/null
run_psql "$TEST_DB" "CREATE TABLE users (id SERIAL, name TEXT); INSERT INTO users (name) VALUES ('Alice'), ('Bob');" >/dev/null
ORIGINAL=$(run_psql "$TEST_DB" "SELECT COUNT(*) FROM users;")
[ "$ORIGINAL" = "2" ] && pass "Base de datos creada con datos" || fail "Error creando datos"

echo "  Ejecutando backup..."
BACKUP_OUTPUT=$(run_db_utils "backup.sh $TEST_DB" 2>&1)
if echo "$BACKUP_OUTPUT" | grep -q "Backup completed successfully"; then
    sleep 1
    BACKUP_FILE=$(ls -t "$PROJECT_DIR/backups/${TEST_DB}_backup_"*.sql.gz 2>/dev/null | head -1)
    if [ -f "$BACKUP_FILE" ]; then
        pass "Backup creado: $(basename $BACKUP_FILE)"
    else
        fail "Backup reportó éxito pero archivo no encontrado"
        ls -la "$PROJECT_DIR/backups/" 2>/dev/null
    fi
else
    fail "Backup falló"
    echo "$BACKUP_OUTPUT" | tail -5
fi

if [ -f "$BACKUP_FILE" ]; then
    run_psql "$TEST_DB" "TRUNCATE users RESTART IDENTITY;" >/dev/null
    AFTER_DELETE=$(run_psql "$TEST_DB" "SELECT COUNT(*) FROM users;")
    [ "$AFTER_DELETE" = "0" ] && pass "Datos eliminados" || fail "Error eliminando datos"

    BACKUP_NAME=$(basename "$BACKUP_FILE")
    echo "  Restaurando desde $BACKUP_NAME..."
    run_db_utils "gunzip -c /backups/$BACKUP_NAME | psql -h postgres -U $POSTGRES_USER -d $TEST_DB" >/dev/null
    RESTORED=$(run_psql "$TEST_DB" "SELECT COUNT(*) FROM users;")
    [ "$RESTORED" = "2" ] && pass "Restore exitoso" || fail "Restore falló (esperado: 2, obtenido: $RESTORED)"

    ALICE=$(run_psql "$TEST_DB" "SELECT name FROM users WHERE id=1;")
    [ "$ALICE" = "Alice" ] && pass "Datos verificados" || fail "Datos incorrectos"
else
    fail "Saltando restore (no hay backup)"
fi

echo ""
echo "================================"
echo "  Resultados: $PASSED passed, $FAILED failed"
echo "================================"

[ $FAILED -eq 0 ] && exit 0 || exit 1
