#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$BASE_DIR/logs"
mkdir -p "$LOG_DIR"

echo "================================================"
echo "  Starting all microservices..."
echo "================================================"
echo ""

run_service() {
    local name=$1
    local port=$2
    local dir="$BASE_DIR/$3"

    echo "[$name] Starting on port $port... ($dir)"
    (cd "$dir" && nohup ./mvnw spring-boot:run > "$LOG_DIR/$name.log" 2>&1 &)
    echo "[$name] PID: $!"
}

run_service "Gateway"            8080 "getawayspring"
run_service "Login"              8092 "Login"
run_service "RegistroUsuario"    8093 "RegistroUsuario"
run_service "Inventario"         8094 "ms-Inventario"
run_service "Envios"             8084 "Envios"
run_service "TiendaWeb"          8085 "TiendaWeb"
run_service "Sucursal"           8086 "ms-Sucursal"
run_service "Ventas"             8087 "venta_libro/libro"
run_service "Proveedores"        8098 "proveedor_libro/libros"
run_service "Monitoreo"         8089 "MoniteoreoGeneral"

echo ""
echo "================================================"
echo "  All services starting. Logs in ./logs/"
echo "================================================"
echo ""
echo "  Gateway ........ http://localhost:8080/swagger-ui.html"
  echo "  Login .......... http://localhost:8092/swagger-ui.html"
  echo "  Registro ....... http://localhost:8093/swagger-ui.html"
  echo "  Inventario ..... http://localhost:8094/swagger-ui.html"
  echo "  Envios ......... http://localhost:8084/swagger-ui.html"
  echo "  TiendaWeb ...... http://localhost:8085/swagger-ui.html"
  echo "  Sucursal ....... http://localhost:8086/swagger-ui.html"
  echo "  Ventas ......... http://localhost:8087/swagger-ui.html"
  echo "  Proveedores .... http://localhost:8098/swagger-ui.html"
  echo "  Monitoreo ...... http://localhost:8089/swagger-ui.html"
echo ""
echo "  To stop all: kill $(jobs -p)"
echo "  To tail a log: tail -f logs/<name>.log"
echo "================================================"
