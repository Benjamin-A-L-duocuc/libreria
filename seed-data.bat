@echo off
setlocal enabledelayedexpansion

set "BASE_URL=http://localhost:9080"

echo.
echo ================================================
echo   SEED DATA - Insertando datos de prueba
echo ================================================
echo.

REM --------------------------------------------------
REM  Pre-flight: curl check
REM --------------------------------------------------
curl --version >nul 2>&1
if errorlevel 1 (
    echo [FATAL] curl no encontrado en PATH.
    pause
    exit /b 1
)

REM --------------------------------------------------
REM  Pre-flight: gateway health check
REM --------------------------------------------------
echo [0/10] Verificando Gateway en %BASE_URL% ...
set "GW_OK=0"
for /l %%i in (1,1,15) do (
    curl -sf "%BASE_URL%/api/v1/monitoreo/estado" >nul 2>&1
    if !errorlevel! equ 0 (
        set "GW_OK=1"
        goto :gw_ok
    )
    timeout /t 2 /nobreak >nul
)
:gw_ok
if "%GW_OK%"=="0" (
    echo.
    echo [FATAL] Gateway no disponible en %BASE_URL%
    echo         Asegurese de que los microservicios estan corriendo ^(run-all.bat^)
    echo.
    pause
    exit /b 1
)
echo   [OK] Gateway disponible
echo.

REM --------------------------------------------------
echo [1/10] CREANDO SUCURSALES
REM --------------------------------------------------

echo {"idAdminGeneral":1,"idGerenteSede":1,"nombre":"Sucursal Centro","direccion":"Av. Principal 123, Santiago","fechaInicio":"2025-01-15","telefono":"+56212345678","email":"centro@libreria.cl","estado":true} > "%TEMP%\seed_body.json"
call :api_send POST "/api/sucursales"
if errorlevel 1 goto :fatal
set "ID_CENTRO=%CAPTURED%"
echo   [OK] Sucursal Centro (ID: %ID_CENTRO%)

echo {"idAdminGeneral":1,"idGerenteSede":1,"nombre":"Sucursal Norte","direccion":"Calle Norte 456, Antofagasta","fechaInicio":"2025-03-01","telefono":"+56298765432","email":"norte@libreria.cl","estado":true} > "%TEMP%\seed_body.json"
call :api_send POST "/api/sucursales"
if errorlevel 1 goto :fatal
set "ID_NORTE=%CAPTURED%"
echo   [OK] Sucursal Norte (ID: %ID_NORTE%)

REM --------------------------------------------------
echo [2/10] REGISTRANDO USUARIOS
REM --------------------------------------------------

echo {"nombreCompleto":"Carlos Admin","email":"carlos@libreria.cl","password":"Admin123^!","tipo":"AdministradorGeneral"} > "%TEMP%\seed_body.json"
call :api_fire POST "/api/v1/usuarios"
echo   [OK] Carlos Admin (carlos@libreria.cl)

echo {"nombreCompleto":"Maria Cajero","email":"maria@libreria.cl","password":"Cajero123^!","tipo":"Cajero"} > "%TEMP%\seed_body.json"
call :api_fire POST "/api/v1/usuarios"
echo   [OK] Maria Cajero (maria@libreria.cl)

echo {"nombreCompleto":"Juan Perez","email":"juan@email.cl","password":"Cliente1^!","tipo":"Cliente"} > "%TEMP%\seed_body.json"
call :api_fire POST "/api/v1/usuarios"
echo   [OK] Juan Perez (juan@email.cl)

echo {"nombreCompleto":"Ana Silva","email":"ana@email.cl","password":"Cliente2^!","tipo":"Cliente"} > "%TEMP%\seed_body.json"
call :api_fire POST "/api/v1/usuarios"
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
if errorlevel 1 goto :fatal
set "L1=%CAPTURED%"
call :crear_libro "Breve Historia del Tiempo" "Divulgacion cientifica" "Bantam Books" "Stephen Hawking" 7000 12000 "CIENCIA_FICCION"
if errorlevel 1 goto :fatal
set "L2=%CAPTURED%"
call :crear_libro "1984" "Distopia clasica" "Secker & Warburg" "George Orwell" 4000 10000 "FICCION"
if errorlevel 1 goto :fatal
set "L3=%CAPTURED%"
call :crear_libro "El Principito" "Literatura infantil" "Reynal & Hitchcock" "Antoine Saint-Exupery" 3000 8000 "INFANTIL"
if errorlevel 1 goto :fatal
set "L4=%CAPTURED%"
call :crear_libro "Clean Code" "Buenas practicas de programacion" "Prentice Hall" "Robert C. Martin" 12000 25000 "NO_FICCION"
if errorlevel 1 goto :fatal
set "L5=%CAPTURED%"
echo   [OK] Libros: %L1%, %L2%, %L3%, %L4%, %L5%

REM --------------------------------------------------
echo [4/10] ASIGNANDO STOCK
REM --------------------------------------------------

call :asignar_stock %L1% %ID_CENTRO% 20 5 100
if errorlevel 1 goto :fatal
call :asignar_stock %L2% %ID_CENTRO% 15 5 50
if errorlevel 1 goto :fatal
call :asignar_stock %L3% %ID_CENTRO% 10 3 80
if errorlevel 1 goto :fatal
call :asignar_stock %L4% %ID_CENTRO% 30 10 120
if errorlevel 1 goto :fatal
call :asignar_stock %L5% %ID_CENTRO% 8 2 30
if errorlevel 1 goto :fatal
echo   [OK] Stock asignado en Sucursal Centro

call :asignar_stock %L1% %ID_NORTE% 10 5 80
if errorlevel 1 goto :fatal
call :asignar_stock %L2% %ID_NORTE% 5 3 40
if errorlevel 1 goto :fatal
call :asignar_stock %L3% %ID_NORTE% 8 3 60
if errorlevel 1 goto :fatal
call :asignar_stock %L4% %ID_NORTE% 20 10 100
if errorlevel 1 goto :fatal
call :asignar_stock %L5% %ID_NORTE% 3 1 20
if errorlevel 1 goto :fatal
echo   [OK] Stock asignado en Sucursal Norte

REM --------------------------------------------------
echo [5/10] CREANDO PROVEEDORES
REM --------------------------------------------------

echo {"nombre":"Distribuidora Cultural SPA","rut":"76.123.456-7","direccion":"Av. Providencia 789","telefono":"+56222223333","email":"ventas@cultural.cl","fechaRegistro":"2025-06-01","activo":true,"solicitudes":[]} > "%TEMP%\seed_body.json"
call :api_send POST "/api/v1/proveedor"
set "P1=%CAPTURED%"
echo {"nombre":"Importadora de Libros Ltda","rut":"77.987.654-3","direccion":"Calle Comercio 321","telefono":"+56224445555","email":"info@importadora.cl","fechaRegistro":"2025-06-15","activo":true,"solicitudes":[]} > "%TEMP%\seed_body.json"
call :api_send POST "/api/v1/proveedor"
set "P2=%CAPTURED%"
echo   [OK] Proveedores: ID %P1%, ID %P2%

REM --------------------------------------------------
echo [6/10] CREANDO DESCUENTOS
REM --------------------------------------------------

set "D1="
echo {"nombre":"10%% OFF Semanal","fechaVencimiento":"2026-12-31","porcentaje":10,"cantidad":3} > "%TEMP%\seed_body.json"
call :api_send POST "/api/v1/descuentos"
if not errorlevel 1 (
    set "D1=%CAPTURED%"
    echo   [OK] Descuentos generados (primer ID: !D1!^)
) else (
    echo   [WARN] No se pudieron crear descuentos (continuando sin descuento^)
)

REM --------------------------------------------------
echo [7/10] VENTA PRESENCIAL
REM --------------------------------------------------

echo   Paso 1: Crear venta...
echo {"idSucursal":%ID_CENTRO%,"idCliente":%ID_CLIENTE1%} > "%TEMP%\seed_body.json"
call :api_send POST "/api/v1/ventas/crear"
if errorlevel 1 goto :fatal
set "ID_VENTA=%CAPTURED%"
echo   [OK] Venta creada (ID: %ID_VENTA%, cliente: Juan Perez)

echo   Paso 2: Agregar productos...
echo {"idLibro":%L1%,"cantidad":2} > "%TEMP%\seed_body.json"
call :api_fire POST "/api/v1/ventas/%ID_VENTA%/productos"
echo   [OK] +2 x Cien Anos de Soledad

echo {"idLibro":%L3%,"cantidad":1} > "%TEMP%\seed_body.json"
call :api_fire POST "/api/v1/ventas/%ID_VENTA%/productos"
echo   [OK] +1 x 1984

if not "%D1%"=="" (
    echo {"idLibro":%L5%,"cantidad":1,"descuentoId":%D1%} > "%TEMP%\seed_body.json"
    call :api_fire POST "/api/v1/ventas/%ID_VENTA%/productos"
    echo   [OK] +1 x Clean Code (con 10%% descuento^)
) else (
    echo {"idLibro":%L5%,"cantidad":1} > "%TEMP%\seed_body.json"
    call :api_fire POST "/api/v1/ventas/%ID_VENTA%/productos"
    echo   [OK] +1 x Clean Code (sin descuento^)
)

echo   Paso 3: Finalizar venta...
echo {"medioPago":"EFECTIVO","montoPagado":60000} > "%TEMP%\seed_body.json"
call :api_show_send POST "/api/v1/ventas/%ID_VENTA%/finalizar"
echo.
echo   [OK] Venta finalizada

echo   Verificando unidades vendidas...
curl -sS "%BASE_URL%/api/libros/%L1%" 2>nul | findstr "unidadesVendidas"
echo.

REM --------------------------------------------------
echo [8/10] SESION LOGIN
REM --------------------------------------------------

echo {"idUsuario":%ID_CLIENTE1%} > "%TEMP%\seed_body.json"
call :api_send POST "/api/v1/sesiones/iniciar"
set "ID_SESION=%CAPTURED%"
echo   [OK] Sesion iniciada (ID: %ID_SESION%)

REM --------------------------------------------------
echo [9/10] CREANDO ENVIO
REM --------------------------------------------------

echo {"direccionDestino":"Av. Siempre Viva 742, Santiago","tipoEnvio":"venta_online","notas":"Envio express del libro comprado"} > "%TEMP%\seed_body.json"
call :api_send POST "/api/v1/envios"
set "ID_ENVIO=%CAPTURED%"
echo   [OK] Envio creado (ID: %ID_ENVIO%)

echo {"fechaEnvioProgramada":"2026-07-01T10:00:00"} > "%TEMP%\seed_body.json"
call :api_fire PATCH "/api/v1/envios/%ID_ENVIO%/programar"
echo   [OK] Envio programado

call :api_call POST "/api/v1/envios/%ID_ENVIO%/iniciar"
echo   [OK] Envio en transito

call :api_call POST "/api/v1/envios/%ID_ENVIO%/recibir"
echo   [OK] Envio recibido

REM --------------------------------------------------
echo [10/10] VERIFICACIONES
REM --------------------------------------------------

echo   Estado del sistema:
curl -sS "%BASE_URL%/api/v1/monitoreo/estado" 2>nul
if errorlevel 1 echo   (monitoreo no disponible)
echo.

REM --------------------------------------------------
echo ================================================
echo   DATOS DE PRUEBA INSERTADOS
REM ================================================
echo.
echo   Gateway:     http://localhost:9080/swagger-ui.html
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
pause
goto :eof

REM ============================================================
REM  SUBROUTINES
REM ============================================================

:fatal
echo.
echo [FATAL] Error critico. No se puede continuar.
echo.
pause
exit /b 1

REM  api_send: POST/PATCH with body from %TEMP%\seed_body.json, extract id
:api_send
set "CAPTURED="
curl -sS -X %~1 "%BASE_URL%%~2" -H "Content-Type: application/json" -d "@%TEMP%\seed_body.json" > "%TEMP%\seed_cap.txt" 2>&1
set "CURL_RC=!errorlevel!"
del "%TEMP%\seed_body.json" 2>nul
if "!CURL_RC!" neq "0" (
    echo   [CURL ERROR] %~1 %~2
    type "%TEMP%\seed_cap.txt"
    del "%TEMP%\seed_cap.txt" 2>nul
    exit /b 1
)
powershell -NoProfile -Command "$c = Get-Content '%TEMP%\seed_cap.txt' -Raw -ErrorAction SilentlyContinue; if ($c) { try { $j = ConvertFrom-Json -InputObject $c; $id = if ($j -is [array]) { $j[0].id } else { $j.id }; if ($null -ne $id) { Write-Output $id } } catch {} }" > "%TEMP%\seed_id.txt" 2>nul
for /f "usebackq delims=" %%x in ("%TEMP%\seed_id.txt") do if "!CAPTURED!"=="" set "CAPTURED=%%x"
if "!CAPTURED!"=="" (
    echo   [ERROR] No se pudo extraer ID de: %~1 %~2
    type "%TEMP%\seed_cap.txt"
    echo.
    del "%TEMP%\seed_id.txt" "%TEMP%\seed_cap.txt" 2>nul
    exit /b 1
)
del "%TEMP%\seed_id.txt" "%TEMP%\seed_cap.txt" 2>nul
exit /b 0

REM  api_fire: POST/PATCH with body from %TEMP%\seed_body.json, fire-and-forget
:api_fire
curl -sf -X %~1 "%BASE_URL%%~2" -H "Content-Type: application/json" -d "@%TEMP%\seed_body.json" >nul 2>&1
set "CURL_RC=!errorlevel!"
del "%TEMP%\seed_body.json" 2>nul
if "!CURL_RC!" neq "0" echo   [ERROR] %~1 %~2
exit /b 0

REM  api_show_send: POST/PATCH with body from %TEMP%\seed_body.json, display response
:api_show_send
curl -sS -X %~1 "%BASE_URL%%~2" -H "Content-Type: application/json" -d "@%TEMP%\seed_body.json"
del "%TEMP%\seed_body.json" 2>nul
exit /b 0

REM  api_call: POST/PATCH without body, fire-and-forget
:api_call
curl -sf -X %~1 "%BASE_URL%%~2" >nul 2>&1
if !errorlevel! neq 0 echo   [ERROR] %~1 %~2
exit /b 0

REM  api_get_id: GET request, extract id from response
:api_get_id
set "CAPTURED="
curl -sS "%BASE_URL%%~1" > "%TEMP%\seed_cap.txt" 2>&1
if !errorlevel! neq 0 (
    echo   [CURL ERROR] GET %~1
    type "%TEMP%\seed_cap.txt"
    del "%TEMP%\seed_cap.txt" 2>nul
    exit /b 1
)
powershell -NoProfile -Command "$c = Get-Content '%TEMP%\seed_cap.txt' -Raw -ErrorAction SilentlyContinue; if ($c) { try { $j = ConvertFrom-Json -InputObject $c; $id = if ($j -is [array]) { $j[0].id } else { $j.id }; if ($null -ne $id) { Write-Output $id } } catch {} }" > "%TEMP%\seed_id.txt" 2>nul
for /f "usebackq delims=" %%x in ("%TEMP%\seed_id.txt") do if "!CAPTURED!"=="" set "CAPTURED=%%x"
if "!CAPTURED!"=="" (
    echo   [ERROR] No se pudo extraer ID de: GET %~1
    type "%TEMP%\seed_cap.txt"
    echo.
    del "%TEMP%\seed_id.txt" "%TEMP%\seed_cap.txt" 2>nul
    exit /b 1
)
del "%TEMP%\seed_id.txt" "%TEMP%\seed_cap.txt" 2>nul
exit /b 0

REM  crear_libro: POST to /api/libros, extract id
:crear_libro
set "CAPTURED="
echo {"nombre":"%~1","descripcion":"%~2","editorial":"%~3","autor":"%~4","precioCompra":%~5,"precioVenta":%~6,"categoria":"%~7","fechaCreacion":"2026-01-15"} > "%TEMP%\seed_body.json"
curl -sS -X POST "%BASE_URL%/api/libros" -H "Content-Type: application/json" -d "@%TEMP%\seed_body.json" > "%TEMP%\seed_cap.txt" 2>&1
set "CURL_RC=!errorlevel!"
del "%TEMP%\seed_body.json" 2>nul
if "!CURL_RC!" neq "0" (
    echo   [CURL ERROR] Crear libro: %~1
    type "%TEMP%\seed_cap.txt"
    del "%TEMP%\seed_cap.txt" 2>nul
    exit /b 1
)
powershell -NoProfile -Command "$c = Get-Content '%TEMP%\seed_cap.txt' -Raw -ErrorAction SilentlyContinue; if ($c) { try { $j = ConvertFrom-Json -InputObject $c; $id = if ($j -is [array]) { $j[0].id } else { $j.id }; if ($null -ne $id) { Write-Output $id } } catch {} }" > "%TEMP%\seed_id.txt" 2>nul
for /f "usebackq delims=" %%x in ("%TEMP%\seed_id.txt") do if "!CAPTURED!"=="" set "CAPTURED=%%x"
if "!CAPTURED!"=="" (
    echo   [ERROR] No se pudo extraer ID del libro: %~1
    type "%TEMP%\seed_cap.txt"
    echo.
    del "%TEMP%\seed_id.txt" "%TEMP%\seed_cap.txt" 2>nul
    exit /b 1
)
del "%TEMP%\seed_id.txt" "%TEMP%\seed_cap.txt" 2>nul
exit /b 0

REM  asignar_stock: POST to /api/stock-libros
:asignar_stock
echo {"idLibro":%~1,"idSucursal":%~2,"stock":%~3,"stockMinimo":%~4,"stockMaximo":%~5} > "%TEMP%\seed_body.json"
curl -sf -X POST "%BASE_URL%/api/stock-libros" -H "Content-Type: application/json" -d "@%TEMP%\seed_body.json" > "%TEMP%\seed_cap.txt" 2>&1
set "CURL_RC=!errorlevel!"
del "%TEMP%\seed_body.json" 2>nul
if "!CURL_RC!" neq "0" (
    echo   [ERROR] Asignar stock: Libro=%~1 Sucursal=%~2
    type "%TEMP%\seed_cap.txt"
    del "%TEMP%\seed_cap.txt" 2>nul
    exit /b 1
)
del "%TEMP%\seed_cap.txt" 2>nul
exit /b 0
