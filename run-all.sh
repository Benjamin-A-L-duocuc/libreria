#!/bin/bash

BASE_DIR="$(dirname "$0")"

echo "Starting all microservices..."
echo ""

run_service() {
    local name=$1
    local port=$2
    local dir="$BASE_DIR/$name"

    echo "[$name] Starting on port $port..."
    (cd "$dir" && ./mvnw spring-boot:run > "../logs/$name.log" 2>&1) &
    echo "[$name] PID: $!"
}

mkdir -p "$BASE_DIR/logs"

run_service "Login" 8081
run_service "RegistroUsuario" 8082
run_service "Envios" 8084
run_service "TiendaWeb" 8085

echo ""
echo "All services starting. Logs in ./logs/"
echo "  Login  → http://localhost:8081/doc/swagger-ui.html"
echo "  Registro → http://localhost:8082/doc/swagger-ui.html"
echo "  Envios → http://localhost:8084/doc/swagger-ui.html"
echo "  TiendaWeb → http://localhost:8085/doc/swagger-ui.html"
echo ""
echo "To stop: kill $(jobs -p)"
