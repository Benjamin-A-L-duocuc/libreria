#!/bin/bash
# ==========================================================
#  seed-data.sh
#  Populates all microservices with sample data via the
#  API Gateway (port 8080) to demonstrate end-to-end flow.
# ==========================================================

BASE_URL="http://localhost:8080"

# Colours for readability
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

section()   { printf "\n${BLUE}══════════════════════════════════════════════${NC}\n${BLUE}  %s${NC}\n${BLUE}══════════════════════════════════════════════${NC}\n" "$1"; }
ok()        { printf "  ${GREEN}✔${NC} %s\n" "$1"; }
info()      { printf "  ${CYAN}→${NC} %s\n" "$1"; }
highlight() { printf "  ${YELLOW}%s${NC}\n" "$1"; }

# --------------------------------------------------
section "1. CREANDO SUCURSALES"
# --------------------------------------------------
info "Creando Sucursal Centro..."
CENTRO=$(curl -s -X POST "$BASE_URL/api/sucursales" \
  -H "Content-Type: application/json" \
  -d '{"idAdminGeneral":1,"idGerenteSede":1,"nombre":"Sucursal Centro","direccion":"Av. Principal 123, Santiago","fechaInicio":"2025-01-15","telefono":"+56212345678","email":"centro@libreria.cl","estado":true}')
ID_CENTRO=$(echo "$CENTRO" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
ok "Sucursal Centro creada (ID: $ID_CENTRO)"

info "Creando Sucursal Norte..."
NORTE=$(curl -s -X POST "$BASE_URL/api/sucursales" \
  -H "Content-Type: application/json" \
  -d '{"idAdminGeneral":1,"idGerenteSede":1,"nombre":"Sucursal Norte","direccion":"Calle Norte 456, Antofagasta","fechaInicio":"2025-03-01","telefono":"+56298765432","email":"norte@libreria.cl","estado":true}')
ID_NORTE=$(echo "$NORTE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
ok "Sucursal Norte creada (ID: $ID_NORTE)"

# --------------------------------------------------
section "2. REGISTRANDO USUARIOS"
# --------------------------------------------------
info "Registrando Administrador General..."
curl -s -X POST "$BASE_URL/api/v1/usuarios" \
  -H "Content-Type: application/json" \
  -d '{"nombreCompleto":"Carlos Admin","email":"carlos@libreria.cl","password":"Admin123!","tipo":"AdministradorGeneral"}' > /dev/null
ok "Carlos Admin (carlos@libreria.cl)"

info "Registrando Cajero..."
curl -s -X POST "$BASE_URL/api/v1/usuarios" \
  -H "Content-Type: application/json" \
  -d '{"nombreCompleto":"Maria Cajero","email":"maria@libreria.cl","password":"Cajero123!","tipo":"Cajero"}' > /dev/null
ok "Maria Cajero (maria@libreria.cl)"

info "Registrando Cliente 1..."
curl -s -X POST "$BASE_URL/api/v1/usuarios" \
  -H "Content-Type: application/json" \
  -d '{"nombreCompleto":"Juan Perez","email":"juan@email.cl","password":"Cliente1!","tipo":"Cliente"}' > /dev/null
ok "Juan Perez (juan@email.cl)"

info "Registrando Cliente 2..."
curl -s -X POST "$BASE_URL/api/v1/usuarios" \
  -H "Content-Type: application/json" \
  -d '{"nombreCompleto":"Ana Silva","email":"ana@email.cl","password":"Cliente2!","tipo":"Cliente"}' > /dev/null
ok "Ana Silva (ana@email.cl)"

# Obtener IDs para referencia
ID_ADMIN=$(curl -s "$BASE_URL/api/v1/usuarios/email/carlos@libreria.cl" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
ID_CAJERO=$(curl -s "$BASE_URL/api/v1/usuarios/email/maria@libreria.cl" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
ID_CLIENTE1=$(curl -s "$BASE_URL/api/v1/usuarios/email/juan@email.cl" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
ID_CLIENTE2=$(curl -s "$BASE_URL/api/v1/usuarios/email/ana@email.cl" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
highlight "  → IDs: Admin=$ID_ADMIN, Cajero=$ID_CAJERO, Cliente1=$ID_CLIENTE1, Cliente2=$ID_CLIENTE2"

# --------------------------------------------------
section "3. CREANDO LIBROS (Inventario)"
# --------------------------------------------------
crear_libro() {
    local nombre=$1 desc=$2 ed=$3 autor=$4 pCompra=$5 pVenta=$6 cat=$7
    local result=$(curl -s -X POST "$BASE_URL/api/libros" \
      -H "Content-Type: application/json" \
      -d "{\"nombre\":\"$nombre\",\"descripcion\":\"$desc\",\"editorial\":\"$ed\",\"autor\":\"$autor\",\"precioCompra\":$pCompra,\"precioVenta\":$pVenta,\"categoria\":\"$cat\",\"fechaCreacion\":\"2026-01-15\"}")
    echo "$result" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2
}

L1=$(crear_libro "Cien Años de Soledad" "Novela del realismo mágico" "Sudamericana" "Gabriel García Márquez" 5000 15000 "FICCION")
L2=$(crear_libro "Breve Historia del Tiempo" "Divulgación científica" "Bantam Books" "Stephen Hawking" 7000 12000 "CIENCIA_FICCION")
L3=$(crear_libro "1984" "Distopía clásica" "Secker & Warburg" "George Orwell" 4000 10000 "FICCION")
L4=$(crear_libro "El Principito" "Literatura infantil" "Reynal & Hitchcock" "Antoine Saint-Exupéry" 3000 8000 "INFANTIL")
L5=$(crear_libro "Clean Code" "Buenas prácticas de programación" "Prentice Hall" "Robert C. Martin" 12000 25000 "TECNOLOGIA")

ok "Libros creados: $L1,$L2,$L3,$L4,$L5"

# --------------------------------------------------
section "4. ASIGNANDO STOCK A SUCURSALES"
# --------------------------------------------------
asignar_stock() {
    local idLibro=$1 idSuc=$2 stock=$3 min=$4 max=$5
    curl -s -X POST "$BASE_URL/api/stock-libros" \
      -H "Content-Type: application/json" \
      -d "{\"idLibro\":$idLibro,\"idSucursal\":$idSuc,\"stock\":$stock,\"stockMinimo\":$min,\"stockMaximo\":$max}" > /dev/null
}

info "Stock en Sucursal Centro (ID: $ID_CENTRO)..."
asignar_stock $L1 $ID_CENTRO 20 5 100
asignar_stock $L2 $ID_CENTRO 15 5 50
asignar_stock $L3 $ID_CENTRO 10 3 80
asignar_stock $L4 $ID_CENTRO 30 10 120
asignar_stock $L5 $ID_CENTRO 8 2 30
ok "Stock asignado en Sucursal Centro"

info "Stock en Sucursal Norte (ID: $ID_NORTE)..."
asignar_stock $L1 $ID_NORTE 10 5 80
asignar_stock $L2 $ID_NORTE 5 3 40
asignar_stock $L3 $ID_NORTE 8 3 60
asignar_stock $L4 $ID_NORTE 20 10 100
asignar_stock $L5 $ID_NORTE 3 1 20
ok "Stock asignado en Sucursal Norte"

highlight "  Total libros en inventario: 10 registros de stock"

# --------------------------------------------------
section "5. CREANDO PROVEEDORES"
# --------------------------------------------------
P1=$(curl -s -X POST "$BASE_URL/api/v1/proveedor" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Distribuidora Cultural SPA","rut":"76.123.456-7","direccion":"Av. Providencia 789","telefono":"+56222223333","email":"ventas@cultural.cl","fechaRegistro":"2025-06-01","activo":true,"solicitudes":[]}' | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
P2=$(curl -s -X POST "$BASE_URL/api/v1/proveedor" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Importadora de Libros Ltda","rut":"77.987.654-3","direccion":"Calle Comercio 321","telefono":"+56224445555","email":"info@importadora.cl","fechaRegistro":"2025-06-15","activo":true,"solicitudes":[]}' | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
ok "Proveedores creados: ID $P1, ID $P2"

# --------------------------------------------------
section "6. CREANDO DESCUENTOS"
# --------------------------------------------------
D1=$(curl -s -X POST "$BASE_URL/api/v1/descuentos" \
  -H "Content-Type: application/json" \
  -d '{"nombre":"10% OFF Semanal","fechaVencimiento":"2026-12-31","porcentaje":10,"cantidad":3}' | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
ok "Descuentos generados (3 códigos, primer ID: $D1)"

# --------------------------------------------------
section "7. VENTA PRESENCIAL (FLUJO COMPLETO)"
# --------------------------------------------------

highlight "═══ Paso 1: Crear venta (cajero) ═══"
VENTA=$(curl -s -X POST "$BASE_URL/api/v1/ventas/crear" \
  -H "Content-Type: application/json" \
  -d "{\"idSucursal\":$ID_CENTRO,\"idCliente\":$ID_CLIENTE1}")
ID_VENTA=$(echo "$VENTA" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
ok "Venta creada (ID: $ID_VENTA, cliente: Juan Perez)"

highlight "═══ Paso 2: Agregar productos ═══"
info "Agregando 'Cien Años de Soledad' (x2)..."
curl -s -X POST "$BASE_URL/api/v1/ventas/$ID_VENTA/productos" \
  -H "Content-Type: application/json" \
  -d "{\"idLibro\":$L1,\"cantidad\":2}" > /dev/null
ok "+2 x Cien Años de Soledad"

info "Agregando '1984' (x1)..."
curl -s -X POST "$BASE_URL/api/v1/ventas/$ID_VENTA/productos" \
  -H "Content-Type: application/json" \
  -d "{\"idLibro\":$L3,\"cantidad\":1}" > /dev/null
ok "+1 x 1984"

info "Agregando 'Clean Code' (x1) con descuento..."
curl -s -X POST "$BASE_URL/api/v1/ventas/$ID_VENTA/productos" \
  -H "Content-Type: application/json" \
  -d "{\"idLibro\":$L5,\"cantidad\":1,\"descuentoId\":$D1}" > /dev/null
ok "+1 x Clean Code (descuento 10% aplicado)"

highlight "═══ Paso 3: Ver venta antes de pagar ═══"
VENTA_PRE=$(curl -s "$BASE_URL/api/v1/ventas/$ID_VENTA")
echo -e "  Precio antes de impuestos: $(echo "$VENTA_PRE" | grep -o '"subtotal":[0-9.]*' | cut -d: -f2)"
echo -e "  Descuento total:           $(echo "$VENTA_PRE" | grep -o '"descuentoTotal":[0-9.]*' | cut -d: -f2)"

highlight "═══ Paso 4: Finalizar venta (pago efectivo) ═══"
VENTA_FIN=$(curl -s -X POST "$BASE_URL/api/v1/ventas/$ID_VENTA/finalizar" \
  -H "Content-Type: application/json" \
  -d '{"medioPago":"EFECTIVO","montoPagado":60000}')

echo -e "  Subtotal:      \$ $(echo "$VENTA_FIN" | grep -o '"subtotal":[0-9.]*' | cut -d: -f2)"
echo -e "  Descuento:     \$ $(echo "$VENTA_FIN" | grep -o '"descuentoTotal":[0-9.]*' | cut -d: -f2)"
echo -e "  Impuestos:     \$ $(echo "$VENTA_FIN" | grep -o '"impuestos":[0-9.]*' | cut -d: -f2)"
echo -e "  Total:         \$ $(echo "$VENTA_FIN" | grep -o '"total":[0-9.]*' | cut -d: -f2)"
echo -e "  Monto pagado:  \$ $(echo "$VENTA_FIN" | grep -o '"montoPagado":[0-9.]*' | cut -d: -f2)"
echo -e "  Vuelto:        \$ $(echo "$VENTA_FIN" | grep -o '"vuelto":[0-9.]*' | cut -d: -f2)"
ok "Venta finalizada correctamente"

highlight "═══ Verificar: unidadesVendidas actualizadas en Inventario ═══"
UNIDS=$(curl -s "$BASE_URL/api/libros/$L1" | grep -o '"unidadesVendidas":[0-9]*' | cut -d: -f2)
echo -e "  'Cien Años de Soledad' — unidadesVendidas: $UNIDS (debería ser 2)"

# --------------------------------------------------
section "8. COMPRA ONLINE (FLUJO COMPLETO)"
# --------------------------------------------------
highlight "═══ Cliente crea orden en TiendaWeb ═══"
info "Juan Perez (ID: $ID_CLIENTE1) inicia sesión..."
SESION=$(curl -s -X POST "$BASE_URL/api/v1/sesiones/iniciar" \
  -H "Content-Type: application/json" \
  -d "{\"idUsuario\":$ID_CLIENTE1}")
ID_SESION=$(echo "$SESION" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
ok "Sesión iniciada (ID: $ID_SESION)"

# --------------------------------------------------
section "9. CREANDO ENVÍO"
# --------------------------------------------------
ENVIO=$(curl -s -X POST "$BASE_URL/api/v1/envios" \
  -H "Content-Type: application/json" \
  -d '{"direccionDestino":"Av. Siempre Viva 742, Santiago","tipoEnvio":"venta_online","notas":"Envío express del libro comprado"}')
ID_ENVIO=$(echo "$ENVIO" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
FOLIO=$(echo "$ENVIO" | grep -o '"folio":"[^"]*"' | cut -d\" -f4)
ok "Envío creado (ID: $ID_ENVIO, Folio: $FOLIO)"

info "Programando envío..."
curl -s -X PATCH "$BASE_URL/api/v1/envios/$ID_ENVIO/programar" \
  -H "Content-Type: application/json" \
  -d '{"fechaEnvioProgramada":"2026-07-01T10:00:00"}' > /dev/null
ok "Envío programado para 2026-07-01"

info "Iniciando envío..."
curl -s -X POST "$BASE_URL/api/v1/envios/$ID_ENVIO/iniciar" > /dev/null
ok "Envío en tránsito"

info "Recibiendo envío..."
curl -s -X POST "$BASE_URL/api/v1/envios/$ID_ENVIO/recibir" > /dev/null
ok "Envío recibido"

# --------------------------------------------------
section "10. VERIFICANDO ESTADO DEL SISTEMA (Monitoreo)"
# --------------------------------------------------
ESTADO=$(curl -s "$BASE_URL/api/v1/monitoreo/estado")
info "Estado del sistema:"
echo "$ESTADO" | tr -d '{}"' | tr ',' '\n' | while IFS=: read -r key val; do
    color="$GREEN"
    [ "$val" = " \"CAIDO\"" ] && color="$YELLOW"
    echo -e "  ${color}$key: $val${NC}"
done

# --------------------------------------------------
section "VERIFICACIONES CRUZADAS"
# --------------------------------------------------
highlight "→ Leer sucursales desde Sucursal MS:"
curl -s "$BASE_URL/api/sucursales" | grep -o '"nombre":"[^"]*"' | while read n; do echo "  • $n"; done

highlight "→ Libros en inventario:"
curl -s "$BASE_URL/api/libros" | grep -o '"nombre":"[^"]*"' | while read n; do echo "  • $n"; done

highlight "→ Ventas registradas:"
curl -s "$BASE_URL/api/v1/ventas" | grep -o '"id":[0-9]*,"idSucursal":[0-9]*,"productos":\[{' | wc -l | xargs -I{} echo "  • {} venta(s) registrada(s)"

highlight "→ Usuarios registrados:"
curl -s "$BASE_URL/api/v1/usuarios" | grep -o '"nombreCompleto":"[^"]*"' | while read n; do echo "  • $n"; done

# --------------------------------------------------
section "¡DATOS DE PRUEBA INSERTADOS!"
# --------------------------------------------------
echo -e "  Gateway:     ${CYAN}http://localhost:8080/swagger-ui.html${NC}"
echo -e "  Sucursales:  ${CYAN}${ID_CENTRO}${NC} (Centro), ${CYAN}${ID_NORTE}${NC} (Norte)"
echo -e "  Libros:      ${CYAN}${L1}${NC}-${CYAN}${L5}${NC}"
echo -e "  Usuarios:    ${CYAN}${ID_ADMIN}${NC} (Admin), ${CYAN}${ID_CAJERO}${NC} (Cajero), ${CYAN}${ID_CLIENTE1}${NC} (Juan), ${CYAN}${ID_CLIENTE2}${NC} (Ana)"
echo -e "  Proveedores: ${CYAN}${P1}${NC}, ${CYAN}${P2}${NC}"
echo -e "  Descuentos:  ${CYAN}${D1}${NC} (y 2 más autogenerados)"
echo -e "  Venta:       ${CYAN}${ID_VENTA}${NC} (finalizada)"
echo -e "  Envío:       ${CYAN}${ID_ENVIO}${NC} (Folio: ${FOLIO})"
echo ""
echo -e "  Para ver el detalle de precios en la venta presencial:"
echo -e "    ${YELLOW}curl http://localhost:8080/api/v1/ventas/${ID_VENTA}${NC}"
echo ""
echo -e "  Para probar el flujo nuevamente, borra la DB y corre:"
echo -e "    ${YELLOW}./run-all.sh${NC}"
echo -e "    ${YELLOW}bash scripts/seed-data.sh${NC}"
echo ""
