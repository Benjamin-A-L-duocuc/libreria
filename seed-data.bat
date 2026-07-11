@echo off
setlocal enabledelayedexpansion

set "BASE_URL=http://localhost:8080"

echo.
echo ================================================
echo   SEED DATA - Insertando datos de prueba
echo ================================================
echo.

REM --------------------------------------------------
echo [1/10] CREANDO SUCURSALES
REM --------------------------------------------------

call :api_capture POST "/api/sucursales" "{\"idAdminGeneral\":1,\"idGerenteSede\":1,\"nombre\":\"Sucursal Centro\",\"direccion\":\"Av. Principal 123, Santiago\",\"fechaInicio\":\"2025-01-15\",\"telefono\":\"+56212345678\",\"email\":\"centro@libreria.cl\",\"estado\":true}"
set "ID_CENTRO=%CAPTURED%"
echo   [OK] Sucursal Centro (ID: %ID_CENTRO%)

call :api_capture POST "/api/sucursales" "{\"idAdminGeneral\":1,\"idGerenteSede\":1,\"nombre\":\"Sucursal Norte\",\"direccion\":\"Calle Norte 456, Antofagasta\",\"fechaInicio\":\"2025-03-01\",\"telefono\":\"+56298765432\",\"email\":\"norte@libreria.cl\",\"estado\":true}"
set "ID_NORTE=%CAPTURED%"
echo   [OK] Sucursal Norte (ID: %ID_NORTE%)

REM --------------------------------------------------
echo [2/10] REGISTRANDO USUARIOS
REM --------------------------------------------------

call :api_silent POST "/api/v1/usuarios" "{\"nombreCompleto\":\"Carlos Admin\",\"email\":\"carlos@libreria.cl\",\"password\":\"Admin123!\",\"tipo\":\"AdministradorGeneral\"}"
echo   [OK] Carlos Admin (carlos@libreria.cl)

call :api_silent POST "/api/v1/usuarios" "{\"nombreCompleto\":\"Maria Cajero\",\"email\":\"maria@libreria.cl\",\"password\":\"Cajero123!\",\"tipo\":\"Cajero\"}"
echo   [OK] Maria Cajero (maria@libreria.cl)

call :api_silent POST "/api/v1/usuarios" "{\"nombreCompleto\":\"Juan Perez\",\"email\":\"juan@email.cl\",\"password\":\"Cliente1!\",\"tipo\":\"Cliente\"}"
echo   [OK] Juan Perez (juan@email.cl)

call :api_silent POST "/api/v1/usuarios" "{\"nombreCompleto\":\"Ana Silva\",\"email\":\"ana@email.cl\",\"password\":\"Cliente2!\",\"tipo\":\"Cliente\"}"
echo   [OK] Ana Silva (ana@email.cl)

call :api_get_id "/api/v1/usuarios/email/carlos@libreria.cl"
set "ID_ADMIN=%CAPTURED%"
call :api_get_id "/api/v1/usuarios/email/maria@libreria.cl"
set "ID_CAJERO=%CAPTURED%"
call :api_get_id "/api/v1/usuarios/email/juan@email.cl"
set "ID_CLIENTE1=%CAPTURED%"
call :api_get_id "/api/v1/usuarios/email/ana@email.cl"
set "ID_CLIENTE2=%CAPTURED%"
echo   [i] IDs: Admin=%ID_ADMIN%, Cajero=%ID_CAJERO%, Cliente1=%ID_CLIENTE1%, Cliente2=%ID_CLIENTE2%

REM --------------------------------------------------
echo [3/10] CREANDO LIBROS (Inventario)
REM --------------------------------------------------

call :crear_libro "Cien Anos de Soledad" "Novela del realismo magico" "Sudamericana" "Gabriel Garcia Marquez" 5000 15000 "FICCION"
set "L1=%CAPTURED%"
call :crear_libro "Breve Historia del Tiempo" "Divulgacion cientifica" "Bantam Books" "Stephen Hawking" 7000 12000 "CIENCIA_FICCION"
set "L2=%CAPTURED%"
call :crear_libro "1984" "Distopia clasica" "Secker & Warburg" "George Orwell" 4000 10000 "FICCION"
set "L3=%CAPTURED%"
call :crear_libro "El Principito" "Literatura infantil" "Reynal & Hitchcock" "Antoine Saint-Exupery" 3000 8000 "INFANTIL"
set "L4=%CAPTURED%"
call :crear_libro "Clean Code" "Buenas practicas de programacion" "Prentice Hall" "Robert C. Martin" 12000 25000 "NO_FICCION"
set "L5=%CAPTURED%"
echo   [OK] Libros: %L1%, %L2%, %L3%, %L4%, %L5%

REM --------------------------------------------------
echo [4/10] ASIGNANDO STOCK
REM --------------------------------------------------

call :asignar_stock %L1% %ID_CENTRO% 20 5 100
call :asignar_stock %L2% %ID_CENTRO% 15 5 50
call :asignar_stock %L3% %ID_CENTRO% 10 3 80
call :asignar_stock %L4% %ID_CENTRO% 30 10 120
call :asignar_stock %L5% %ID_CENTRO% 8 2 30
echo   [OK] Stock asignado en Sucursal Centro

call :asignar_stock %L1% %ID_NORTE% 10 5 80
call :asignar_stock %L2% %ID_NORTE% 5 3 40
call :asignar_stock %L3% %ID_NORTE% 8 3 60
call :asignar_stock %L4% %ID_NORTE% 20 10 100
call :asignar_stock %L5% %ID_NORTE% 3 1 20
echo   [OK] Stock asignado en Sucursal Norte

REM --------------------------------------------------
echo [5/10] CREANDO PROVEEDORES
REM --------------------------------------------------

call :api_capture POST "/api/v1/proveedor" "{\"nombre\":\"Distribuidora Cultural SPA\",\"rut\":\"76.123.456-7\",\"direccion\":\"Av. Providencia 789\",\"telefono\":\"+56222223333\",\"email\":\"ventas@cultural.cl\",\"fechaRegistro\":\"2025-06-01\",\"activo\":true,\"solicitudes\":[]}"
set "P1=%CAPTURED%"
call :api_capture POST "/api/v1/proveedor" "{\"nombre\":\"Importadora de Libros Ltda\",\"rut\":\"77.987.654-3\",\"direccion\":\"Calle Comercio 321\",\"telefono\":\"+56224445555\",\"email\":\"info@importadora.cl\",\"fechaRegistro\":\"2025-06-15\",\"activo\":true,\"solicitudes\":[]}"
set "P2=%CAPTURED%"
echo   [OK] Proveedores: ID %P1%, ID %P2%

REM --------------------------------------------------
echo [6/10] CREANDO DESCUENTOS
REM --------------------------------------------------

call :api_capture POST "/api/v1/descuentos" "{\"nombre\":\"10%% OFF Semanal\",\"fechaVencimiento\":1798675200000,\"porcentaje\":10,\"cantidad\":3}"
set "D1=%CAPTURED%"
echo   [OK] Descuentos generados (primer ID: %D1%)

REM --------------------------------------------------
echo [7/10] VENTA PRESENCIAL
REM --------------------------------------------------

echo   Paso 1: Crear venta...
call :api_capture POST "/api/v1/ventas/crear" "{\"idSucursal\":%ID_CENTRO%, \"idCliente\":%ID_CLIENTE1%}"
set "ID_VENTA=%CAPTURED%"
echo   [OK] Venta creada (ID: %ID_VENTA%, cliente: Juan Perez)

echo   Paso 2: Agregar productos...
call :api_silent POST "/api/v1/ventas/%ID_VENTA%/productos" "{\"idLibro\":%L1%, \"cantidad\":2}"
echo   [OK] +2 x Cien Anos de Soledad
call :api_silent POST "/api/v1/ventas/%ID_VENTA%/productos" "{\"idLibro\":%L3%, \"cantidad\":1}"
echo   [OK] +1 x 1984
call :api_silent POST "/api/v1/ventas/%ID_VENTA%/productos" "{\"idLibro\":%L5%, \"cantidad\":1, \"descuentoId\":%D1%}"
echo   [OK] +1 x Clean Code (con 10%% descuento)

echo   Paso 3: Finalizar venta...
call :api_show POST "/api/v1/ventas/%ID_VENTA%/finalizar" "{\"medioPago\":\"EFECTIVO\", \"montoPagado\":60000}"
echo   [OK] Venta finalizada

echo   Verificando unidades vendidas...
call :api_get_id "/api/libros/%L1%"
set "UNIDS_VEND=%CAPTURED%"
echo   [i] Libro %L1% - unidadesVendidas=%UNIDS_VEND%

REM --------------------------------------------------
echo [8/10] SESION LOGIN
REM --------------------------------------------------

call :api_capture POST "/api/v1/sesiones/iniciar" "{\"idUsuario\":%ID_CLIENTE1%}"
set "ID_SESION=%CAPTURED%"
echo   [OK] Sesion iniciada (ID: %ID_SESION%)

REM --------------------------------------------------
echo [9/10] CREANDO ENVIO
REM --------------------------------------------------

call :api_capture POST "/api/v1/envios" "{\"direccionDestino\":\"Av. Siempre Viva 742, Santiago\",\"tipoEnvio\":\"venta_online\",\"notas\":\"Envio express del libro comprado\"}"
set "ID_ENVIO=%CAPTURED%"
echo   [OK] Envio creado (ID: %ID_ENVIO%)

call :api_silent PATCH "/api/v1/envios/%ID_ENVIO%/programar" "{\"fechaEnvioProgramada\":\"2026-07-01T10:00:00\"}"
echo   [OK] Envio programado

call :api_silent POST "/api/v1/envios/%ID_ENVIO%/iniciar"
echo   [OK] Envio en transito

call :api_silent POST "/api/v1/envios/%ID_ENVIO%/recibir"
echo   [OK] Envio recibido

REM --------------------------------------------------
echo [10/10] VERIFICACIONES
REM --------------------------------------------------

echo   Estado del sistema:
curl -sf "%BASE_URL%/api/v1/monitoreo/estado" 2>nul
if errorlevel 1 echo   (monitoreo no disponible)
echo.

REM --------------------------------------------------
echo ================================================
echo   DATOS DE PRUEBA INSERTADOS
echo ================================================
echo.
echo   Gateway:     http://localhost:8080/swagger-ui.html
echo   Sucursales:  %ID_CENTRO% (Centro), %ID_NORTE% (Norte)
echo   Libros:      %L1%, %L2%, %L3%, %L4%, %L5%
echo   Usuarios:    %ID_ADMIN% (Admin), %ID_CAJERO% (Cajero)
echo                %ID_CLIENTE1% (Juan), %ID_CLIENTE2% (Ana)
echo   Proveedores: %P1%, %P2%
echo   Descuentos:  %D1%
echo   Venta:       %ID_VENTA%
echo   Sesion:      %ID_SESION%
echo   Envio:       %ID_ENVIO%
echo.
goto :eof

REM ============================================================
REM  SUBROUTINES
REM ============================================================

:api_silent
if "%~3"=="" (
    curl -s -X %~1 "%BASE_URL%%~2" > "%TEMP%\seed_err.txt" 2>&1
) else (
    curl -s -X %~1 "%BASE_URL%%~2" -H "Content-Type: application/json" -d "%~3" > "%TEMP%\seed_err.txt" 2>&1
)
if %errorlevel% neq 0 (
    echo   [ERROR] %~1 %~2
    type "%TEMP%\seed_err.txt"
)
exit /b 0

:api_capture
set "CAPTURED="
curl -s -X %~1 "%BASE_URL%%~2" -H "Content-Type: application/json" -d "%~3" > "%TEMP%\seed_cap.txt" 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] %~1 %~2
    type "%TEMP%\seed_cap.txt"
    exit /b 0
)
for /f "tokens=2 delims=:," %%x in ('type "%TEMP%\seed_cap.txt"') do (
    if "!CAPTURED!"=="" (
        set "CAPTURED=%%x"
        set "CAPTURED=!CAPTURED: =!"
    )
)
if "!CAPTURED!"=="" (
    echo   [WARN] No se pudo extraer ID de la respuesta:
    type "%TEMP%\seed_cap.txt"
)
exit /b 0

:api_get_id
set "CAPTURED="
curl -s "%BASE_URL%%~1" > "%TEMP%\seed_cap.txt" 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] GET %~1
    type "%TEMP%\seed_cap.txt"
    exit /b 0
)
for /f "tokens=2 delims=:," %%x in ('type "%TEMP%\seed_cap.txt"') do (
    if "!CAPTURED!"=="" (
        set "CAPTURED=%%x"
        set "CAPTURED=!CAPTURED: =!"
    )
)
if "!CAPTURED!"=="" (
    echo   [WARN] No se pudo extraer ID de:
    type "%TEMP%\seed_cap.txt"
)
exit /b 0

:api_show
if "%~3"=="" (
    curl -s -X %~1 "%BASE_URL%%~2" 2>&1
) else (
    curl -s -X %~1 "%BASE_URL%%~2" -H "Content-Type: application/json" -d "%~3" 2>&1
)
if %errorlevel% neq 0 echo   [ERROR] %~1 %~2
exit /b 0

:crear_libro
set "CAPTURED="
curl -s -X POST "%BASE_URL%/api/libros" -H "Content-Type: application/json" -d "{\"nombre\":\"%~1\",\"descripcion\":\"%~2\",\"editorial\":\"%~3\",\"autor\":\"%~4\",\"precioCompra\":%~5,\"precioVenta\":%~6,\"categoria\":\"%~7\",\"fechaCreacion\":\"2026-01-15\"}" > "%TEMP%\seed_cap.txt" 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] Crear libro: %~1
    type "%TEMP%\seed_cap.txt"
    exit /b 0
)
for /f "tokens=2 delims=:," %%x in ('type "%TEMP%\seed_cap.txt"') do (
    if "!CAPTURED!"=="" (
        set "CAPTURED=%%x"
        set "CAPTURED=!CAPTURED: =!"
    )
)
if "!CAPTURED!"=="" (
    echo   [WARN] No se pudo extraer ID del libro:
    type "%TEMP%\seed_cap.txt"
)
exit /b 0

:asignar_stock
curl -s -X POST "%BASE_URL%/api/stock-libros" -H "Content-Type: application/json" -d "{\"idLibro\":%~1,\"idSucursal\":%~2,\"stock\":%~3,\"stockMinimo\":%~4,\"stockMaximo\":%~5}" > "%TEMP%\seed_err.txt" 2>&1
if %errorlevel% neq 0 (
    echo   [ERROR] Asignar stock: Libro=%~1 Sucursal=%~2
    type "%TEMP%\seed_err.txt"
)
exit /b 0
