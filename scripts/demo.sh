#!/bin/bash
# ==========================================================
#  demo.sh — Arranca todo y puebla datos de prueba
#
#  Uso:  bash scripts/demo.sh              (primera vez)
#        bash scripts/demo.sh --clean      (reset + seed)
#  Logs: ./logs/<nombre>.log
# ==========================================================
set -e

CLEAN=0
for arg in "$@"; do [ "$arg" = "--clean" ] && CLEAN=1; done

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="$BASE_DIR/logs"
mkdir -p "$LOG_DIR"

GREEN='\033[0;32m'; BLUE='\033[1;34m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

# --------------------------------------------------
# Clean option: drop all tables in all MS databases
# --------------------------------------------------
if [ "$CLEAN" = "1" ]; then
    echo ""
    echo -e "${YELLOW}⚠  ATENCIÓN: Se borrarán TODOS los datos existentes.${NC}"
    echo -e "${YELLOW}   Bases afectadas: inventario_ms, login_usuario, registro_usuario,${NC}"
    echo -e "${YELLOW}   Envio, Tienda_Web, sucursal_ms, ventas, monitoreo_ms, proveedor${NC}"
    echo -n "¿Continuar? (s/N): "
    read -r confirm
    if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
        echo "Cancelado."
        exit 0
    fi

    DB_USER="pma"
    DB_PASS="adminB"
    DBS=("inventario_ms" "login_usuario" "registro_usuario" "Envio" "Tienda_Web" "sucursal_ms" "ventas" "monitoreo_ms" "proveedor")

    for db in "${DBS[@]}"; do
        echo -n "  Limpiando $db... "
        mysql -u "$DB_USER" -p"$DB_PASS" -N -e "SELECT CONCAT('DROP TABLE IF EXISTS ', table_name, ';') FROM information_schema.tables WHERE table_schema='$db'" 2>/dev/null \
            | mysql -u "$DB_USER" -p"$DB_PASS" "$db" 2>/dev/null && echo "OK" || echo "SKIP (sin tablas)"
    done
    echo -e "${GREEN}  Bases de datos limpias.${NC}"
    echo ""
fi

log()   { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $1"; }
warn()  { echo -e "${YELLOW}[$(date +%H:%M:%S)]  ⚠ $1${NC}"; }
err()   { echo -e "${RED}[$(date +%H:%M:%S)]  ✖ $1${NC}"; }
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            LIBRERÍA — DEMO COMPLETA                ║${NC}"
echo -e "${BLUE}║     Iniciando 10 microservicios + datos prueba     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# --------------------------------------------------
# 1) Matar procesos viejos en los puertos usados
# --------------------------------------------------
log "Limpiando procesos previos..."
for port in 8080 8081 8082 8083 8084 8085 8086 8087 8089 8098; do
    kill "$(lsof -t -i:"$port" 2>/dev/null)" 2>/dev/null || true
done
sleep 2
log "Puertos liberados."

# --------------------------------------------------
# 2) Arrancar cada MS con java -jar
# --------------------------------------------------
SERVICES=(
    "Gateway:8080:getawayspring"
    "Login:8081:Login"
    "RegistroUsuario:8082:RegistroUsuario"
    "Inventario:8083:ms-Inventario"
    "Envios:8084:Envios"
    "TiendaWeb:8085:TiendaWeb"
    "Sucursal:8086:ms-Sucursal"
    "Ventas:8087:venta_libro/libro"
    "Monitoreo:8089:MoniteoreoGeneral"
    "Proveedores:8098:proveedor_libro/libros"
)

for entry in "${SERVICES[@]}"; do
    name="${entry%%:*}"
    rest="${entry#*:}"
    port="${rest%%:*}"
    dir="${rest#*:}"
    jar_path="$BASE_DIR/$dir/target/"*.jar

    log "Iniciando ${name} (puerto ${port})..."
    java -jar $jar_path > "$LOG_DIR/$name.log" 2>&1 &
done
log "Todos los procesos lanzados."

# --------------------------------------------------
# 3) Esperar a que todos respondan /actuator/health
# --------------------------------------------------
echo ""
log "Esperando que los servicios estén listos..."

wait_for() {
    local name=$1 port=$2 max=60
    for i in $(seq 1 $max); do
        if curl -sf "http://localhost:${port}/actuator/health" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✔${NC} ${name} (puerto ${port}) — ${GREEN}UP${NC}"
            return 0
        fi
        sleep 2
    done
    echo -e "  ${RED}✖${NC} ${name} (puerto ${port}) — ${RED}TIMEOUT${NC}"
    return 1
}

wait_for "Gateway"       8080
wait_for "Login"         8081
wait_for "Registro"      8082
wait_for "Inventario"    8083
wait_for "Envios"        8084
wait_for "TiendaWeb"     8085
wait_for "Sucursal"      8086
wait_for "Ventas"        8087
wait_for "Monitoreo"     8089
wait_for "Proveedores"   8098

echo ""
log "Todos los servicios están UP. Sembrando datos..."

# --------------------------------------------------
# 4) Sembrar datos via Gateway (puerto 8080)
# --------------------------------------------------
GW="http://localhost:8080"

api() {
    local method=$1 url=$2 data=$3
    if [ -n "$data" ]; then
        curl -sf -X "$method" "$GW$url" -H "Content-Type: application/json" -d "$data" 2>/dev/null || echo '{}'
    else
        curl -sf -X "$method" "$GW$url" 2>/dev/null || echo '{}'
    fi
}

get_id() { echo "$1" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2 || echo ""; }

# ----- 4a. Sucursales -----
log "Creando sucursales..."
CENTRO=$(api POST "/api/sucursales" '{"idAdminGeneral":1,"idGerenteSede":1,"nombre":"Sucursal Centro","direccion":"Av. Principal 123, Santiago","fechaInicio":"2025-01-15","telefono":"+56212345678","email":"centro@libreria.cl","estado":true}')
ID_C=$(get_id "$CENTRO")
NORTE=$(api POST "/api/sucursales" '{"idAdminGeneral":1,"idGerenteSede":1,"nombre":"Sucursal Norte","direccion":"Calle Norte 456, Antofagasta","fechaInicio":"2025-03-01","telefono":"+56298765432","email":"norte@libreria.cl","estado":true}')
ID_N=$(get_id "$NORTE")
echo -e "  ${GREEN}✔${NC} Centro (ID: $ID_C) | Norte (ID: $ID_N)"

# ----- 4b. Usuarios -----
log "Registrando usuarios..."
api POST "/api/v1/usuarios" '{"nombreCompleto":"Carlos Admin","email":"carlos@libreria.cl","password":"Admin123!","tipo":"AdministradorGeneral"}' > /dev/null
api POST "/api/v1/usuarios" '{"nombreCompleto":"Maria Cajero","email":"maria@libreria.cl","password":"Cajero123!","tipo":"Cajero"}' > /dev/null
api POST "/api/v1/usuarios" '{"nombreCompleto":"Juan Perez","email":"juan@email.cl","password":"Cliente1!","tipo":"Cliente"}' > /dev/null
api POST "/api/v1/usuarios" '{"nombreCompleto":"Ana Silva","email":"ana@email.cl","password":"Cliente2!","tipo":"Cliente"}' > /dev/null

ID_ADMIN=$(get_id "$(api GET "/api/v1/usuarios/email/carlos@libreria.cl")")
ID_CAJERO=$(get_id "$(api GET "/api/v1/usuarios/email/maria@libreria.cl")")
ID_Juan=$(get_id "$(api GET "/api/v1/usuarios/email/juan@email.cl")")
ID_Ana=$(get_id "$(api GET "/api/v1/usuarios/email/ana@email.cl")")
echo -e "  ${GREEN}✔${NC} Admin(ID:$ID_ADMIN) Cajero(ID:$ID_CAJERO) Juan(ID:$ID_Juan) Ana(ID:$ID_Ana)"

# ----- 4c. Libros -----
log "Creando libros (Inventario)..."
crear_libro() {
    get_id "$(api POST "/api/libros" "{\"nombre\":\"$1\",\"descripcion\":\"$2\",\"editorial\":\"$3\",\"autor\":\"$4\",\"precioCompra\":$5,\"precioVenta\":$6,\"categoria\":\"$7\",\"fechaCreacion\":\"2026-01-15\"}")"
}
L1=$(crear_libro "Cien Años de Soledad" "Novela del realismo mágico" "Sudamericana" "Gabriel García Márquez" 5000 15000 "FICCION")
L2=$(crear_libro "Breve Historia del Tiempo" "Divulgación científica" "Bantam Books" "Stephen Hawking" 7000 12000 "CIENCIA_FICCION")
L3=$(crear_libro "1984" "Distopía clásica" "Secker & Warburg" "George Orwell" 4000 10000 "FICCION")
L4=$(crear_libro "El Principito" "Literatura infantil" "Reynal & Hitchcock" "Antoine Saint-Exupéry" 3000 8000 "INFANTIL")
L5=$(crear_libro "El Arte de la Guerra" "Estrategia militar clásica" "Editorial Universitaria" "Sun Tzu" 4000 9000 "NO_FICCION")
echo -e "  ${GREEN}✔${NC} 5 libros: IDs $(echo $L1 $L2 $L3 $L4 $L5 | tr ' ' '-')"

# ----- 4d. Stock -----
log "Asignando stock..."
asignar() { api POST "/api/stock-libros" "{\"idLibro\":$1,\"idSucursal\":$2,\"stock\":$3,\"stockMinimo\":$4,\"stockMaximo\":$5}" > /dev/null; }
asignar $L1 $ID_C 20 5 100; asignar $L2 $ID_C 15 5 50;  asignar $L3 $ID_C 10 3 80;  asignar $L4 $ID_C 30 10 120; asignar $L5 $ID_C 8 2 30
asignar $L1 $ID_N 10 5 80;  asignar $L2 $ID_N 5 3 40;   asignar $L3 $ID_N 8 3 60;   asignar $L4 $ID_N 20 10 100; asignar $L5 $ID_N 3 1 20
echo -e "  ${GREEN}✔${NC} 10 registros de stock en 2 sucursales"

# ----- 4e. Proveedores -----
log "Creando proveedores..."
P1=$(get_id "$(api POST "/api/v1/proveedor" '{"nombre":"Distribuidora Cultural SPA","rut":"76.123.456-7","direccion":"Av. Providencia 789","telefono":"+56222223333","email":"ventas@cultural.cl","fechaRegistro":"2025-06-01","activo":true,"solicitudes":[]}')")
P2=$(get_id "$(api POST "/api/v1/proveedor" '{"nombre":"Importadora de Libros Ltda","rut":"77.987.654-3","direccion":"Calle Comercio 321","telefono":"+56224445555","email":"info@importadora.cl","fechaRegistro":"2025-06-15","activo":true,"solicitudes":[]}')")
echo -e "  ${GREEN}✔${NC} Proveedores: ID $P1, ID $P2"

# ----- 4f. Descuentos -----
log "Creando descuentos..."
D1=$(get_id "$(api POST "/api/v1/descuentos" '{"nombre":"10% OFF Semanal","fechaVencimiento":"2026-12-31","porcentaje":10,"cantidad":3}')")
echo -e "  ${GREEN}✔${NC} 3 códigos de descuento generados (primer ID: $D1)"

# ----- 4g. Venta presencial -----
log "FLUJO: Venta presencial..."
V=$(get_id "$(api POST "/api/v1/ventas/crear" "{\"idSucursal\":$ID_C,\"idCliente\":$ID_Juan}")")
echo -e "  ${CYAN}→${NC} Venta $V creada (cajero)"
api POST "/api/v1/ventas/$V/productos" "{\"idLibro\":$L1,\"cantidad\":2}" > /dev/null
echo -e "  ${CYAN}→${NC} +2 x Cien Años de Soledad"
api POST "/api/v1/ventas/$V/productos" "{\"idLibro\":$L3,\"cantidad\":1}" > /dev/null
echo -e "  ${CYAN}→${NC} +1 x 1984"
api POST "/api/v1/ventas/$V/productos" "{\"idLibro\":$L5,\"cantidad\":1,\"descuentoId\":$D1}" > /dev/null
echo -e "  ${CYAN}→${NC} +1 x El Arte de la Guerra (con 10% descuento)"
F=$(api POST "/api/v1/ventas/$V/finalizar" '{"medioPago":"EFECTIVO","montoPagado":65000}')
echo -e "  ${GREEN}✔${NC} Venta finalizada:"
echo -e "     Subtotal:   \$$(echo "$F" | grep -o '"subtotal":[0-9.]*' | cut -d: -f2)"
echo -e "     Descuento: -\$$(echo "$F" | grep -o '"descuentoTotal":[0-9.]*' | cut -d: -f2)"
echo -e "     Impuestos:  \$$(echo "$F" | grep -o '"impuestos":[0-9.]*' | cut -d: -f2)"
echo -e "     Total:      \$$(echo "$F" | grep -o '"total":[0-9.]*' | cut -d: -f2)"
echo -e "     Vuelto:     \$$(echo "$F" | grep -o '"vuelto":[0-9.]*' | cut -d: -f2)"
UNIDS1=$(api GET "/api/libros/$L1" | grep -o '"unidadesVendidas":[0-9]*' | cut -d: -f2)
echo -e "  ${GREEN}✔${NC} unidadesVendidas de '$L1' = $UNIDS1 (Inventario ← Ventas)"

# ----- 4h. Sesión Login -----
log "FLUJO: Login..."
SES=$(api POST "/api/v1/sesiones/iniciar" "{\"idUsuario\":$ID_Juan}")
ID_SES=$(get_id "$SES")
echo -e "  ${GREEN}✔${NC} Sesión $ID_SES iniciada para Juan"

# ----- 4i. Envío -----
log "FLUJO: Envío..."
ENV=$(api POST "/api/v1/envios" '{"direccionDestino":"Av. Siempre Viva 742, Santiago","tipoEnvio":"venta_online","notas":"Envío express"}')
ID_ENV=$(get_id "$ENV")
FOLIO=$(echo "$ENV" | grep -o '"folio":"[^"]*"' | cut -d\" -f4)
echo -e "  ${CYAN}→${NC} Envío $ID_ENV creado (Folio: $FOLIO)"
api PATCH "/api/v1/envios/$ID_ENV/programar" '{"fechaEnvioProgramada":"2026-07-01T10:00:00"}' > /dev/null
api POST "/api/v1/envios/$ID_ENV/iniciar" > /dev/null
api POST "/api/v1/envios/$ID_ENV/recibir" > /dev/null
echo -e "  ${GREEN}✔${NC} Envío: pendiente → programado → en tránsito → recibido"

# --------------------------------------------------
# 5) Mostrar resumen
# --------------------------------------------------
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   RESUMEN DEL SISTEMA              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}Sucursales:${NC}"
curl -s "$GW/api/sucursales" | grep -o '"nombre":"[^"]*"' | while read n; do echo "  • $n"; done

echo -e "\n${YELLOW}Libros en Inventario:${NC}"
curl -s "$GW/api/libros" | grep -o '"nombre":"[^"]*"' | while read n; do echo "  • $n"; done

echo -e "\n${YELLOW}Stock disponible (Centro):${NC}"
curl -s "$GW/api/stock-libros" | python3 -c "
import sys,json
data=json.load(sys.stdin)
for s in data:
    print(f'  • Libro ID {s[\"idLibro\"]}: {s[\"stock\"]} unidades (mín: {s[\"stockMinimo\"]}, máx: {s[\"stockMaximo\"]})')" 2>/dev/null || echo "  (no stock data)"

echo -e "\n${YELLOW}Usuarios registrados:${NC}"
curl -s "$GW/api/v1/usuarios" | grep -o '"nombreCompleto":"[^"]*"' | while read n; do echo "  • $n"; done

echo -e "\n${YELLOW}Ventas realizadas:${NC}"
NV=$(curl -s "$GW/api/v1/ventas" | grep -o '"id":[0-9]*,"idSucursal"' | wc -l)
echo "  • $NV venta(s) registrada(s)"

echo -e "\n${YELLOW}Estado del sistema (Monitoreo):${NC}"
curl -s "$GW/api/v1/monitoreo/estado" | python3 -c "
import sys,json
data=json.load(sys.stdin)
for k,v in data.items():
    print(f'  • {k}: {\"🟢\" if v==\"ACTIVO\" else \"🔴\"} {v}')" 2>/dev/null

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Demo completa — todos los MS funcionando${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}Swagger UI (Gateway):${NC} http://localhost:8080/swagger-ui.html"
echo -e "  ${CYAN}Monitoreo estado:${NC}    http://localhost:8080/api/v1/monitoreo/estado"
echo -e "  ${CYAN}Detalle venta:${NC}       http://localhost:8080/api/v1/ventas/$V"
echo -e "  ${CYAN}Logs:${NC}               $LOG_DIR/"
echo ""
echo -e "  Para detener: ${YELLOW}kill \$(lsof -t -i:8080 -i:8081 -i:8082 -i:8083 -i:8084 -i:8085 -i:8086 -i:8087 -i:8089 -i:8098)${NC}"
echo ""
