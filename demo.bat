@echo off
setlocal enabledelayedexpansion

set "BASE_DIR=%~dp0"
set "LOG_DIR=%BASE_DIR%\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: --------------------------------------------------
:: Pre-flight checks
:: --------------------------------------------------
echo Checking prerequisites...

java -version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Java (JDK 21) is not installed or not in PATH.
    echo   Install JDK 21 from https://adoptium.net/ and ensure java is in PATH.
    pause
    exit /b 1
)

curl --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] curl is not available.
    echo   Windows 10 build 17063+ includes curl natively.
    echo   For older Windows, download curl from https://curl.se/windows/
    pause
    exit /b 1
)

echo   All prerequisites OK.
echo.

set "GW=http://localhost:8080"

echo ================================================
echo   LIBRERIA - COMPLETE DEMO
echo   Starting 10 microservices + seed data
echo ================================================
echo.

:: --------------------------------------------------
:: 1. Kill existing processes on our ports
:: --------------------------------------------------
echo [1/6] Cleaning previous processes...
for %%p in (8080 8092 8093 8094 8084 8085 8086 8087 8089 8098) do (
    for /f "tokens=*" %%a in ('netstat -ano ^| findstr /R "%%p[^0-9]"') do (
        set "line=%%a"
        set "PID="
        for %%b in (%%a) do set "PID=%%b"
        if defined PID (
            taskkill /F /PID !PID! > nul 2>&1
        )
    )
)
timeout /t 3 /nobreak > nul
echo   Ports cleared.

:: --------------------------------------------------
:: 2. Start all microservices
:: --------------------------------------------------
echo [2/6] Launching microservices...

set "SERVICES=Gateway:8080:getawayspring Login:8092:Login RegistroUsuario:8093:RegistroUsuario Inventario:8094:ms-Inventario Envios:8084:Envios TiendaWeb:8085:TiendaWeb Sucursal:8086:ms-Sucursal Ventas:8087:venta_libro\libro Monitoreo:8089:MoniteoreoGeneral Proveedores:8098:proveedor_libro\libros"

for %%s in (%SERVICES%) do (
    for /f "tokens=1-3 delims=:" %%a in ("%%s") do (
        echo   Starting %%a (port %%b)...
        start "Libreria-%%a" /D "%BASE_DIR%\%%c" cmd /k ".\mvnw.cmd spring-boot:run"
    )
)

:: --------------------------------------------------
:: 3. Wait for services to be ready
:: --------------------------------------------------
echo [3/6] Waiting for services to be ready...
timeout /t 60 /nobreak > nul

:: --------------------------------------------------
:: 4. Seed data via Gateway
:: --------------------------------------------------
echo [4/6] Seeding sample data...

call :api POST "/api/sucursales" "{\"idAdminGeneral\":1,\"idGerenteSede\":1,\"nombre\":\"Sucursal Centro\",\"direccion\":\"Av. Principal 123, Santiago\",\"fechaInicio\":\"2025-01-15\",\"telefono\":\"+56212345678\",\"email\":\"centro@libreria.cl\",\"estado\":true}"
call :api POST "/api/sucursales" "{\"idAdminGeneral\":1,\"idGerenteSede\":1,\"nombre\":\"Sucursal Norte\",\"direccion\":\"Calle Norte 456, Antofagasta\",\"fechaInicio\":\"2025-03-01\",\"telefono\":\"+56298765432\",\"email\":\"norte@libreria.cl\",\"estado\":true}"

call :api POST "/api/v1/usuarios" "{\"nombreCompleto\":\"Carlos Admin\",\"email\":\"carlos@libreria.cl\",\"password\":\"Admin123!\",\"tipo\":\"AdministradorGeneral\"}"
call :api POST "/api/v1/usuarios" "{\"nombreCompleto\":\"Maria Cajero\",\"email\":\"maria@libreria.cl\",\"password\":\"Cajero123!\",\"tipo\":\"Cajero\"}"
call :api POST "/api/v1/usuarios" "{\"nombreCompleto\":\"Juan Perez\",\"email\":\"juan@email.cl\",\"password\":\"Cliente1!\",\"tipo\":\"Cliente\"}"
call :api POST "/api/v1/usuarios" "{\"nombreCompleto\":\"Ana Silva\",\"email\":\"ana@email.cl\",\"password\":\"Cliente2!\",\"tipo\":\"Cliente\"}"

call :api POST "/api/libros" "{\"nombre\":\"Cien Anios de Soledad\",\"descripcion\":\"Novela del realismo magico\",\"editorial\":\"Sudamericana\",\"autor\":\"Gabriel Garcia Marquez\",\"precioCompra\":5000,\"precioVenta\":15000,\"categoria\":\"FICCION\",\"fechaCreacion\":\"2026-01-15\"}"
call :api POST "/api/libros" "{\"nombre\":\"Breve Historia del Tiempo\",\"descripcion\":\"Divulgacion cientifica\",\"editorial\":\"Bantam Books\",\"autor\":\"Stephen Hawking\",\"precioCompra\":7000,\"precioVenta\":12000,\"categoria\":\"CIENCIA_FICCION\",\"fechaCreacion\":\"2026-01-15\"}"
call :api POST "/api/libros" "{\"nombre\":\"1984\",\"descripcion\":\"Distopia clasica\",\"editorial\":\"Secker and Warburg\",\"autor\":\"George Orwell\",\"precioCompra\":4000,\"precioVenta\":10000,\"categoria\":\"FICCION\",\"fechaCreacion\":\"2026-01-15\"}"

call :api POST "/api/v1/proveedor" "{\"nombre\":\"Distribuidora Cultural SPA\",\"rut\":\"76.123.456-7\",\"direccion\":\"Av. Providencia 789\",\"telefono\":\"+56222223333\",\"email\":\"ventas@cultural.cl\",\"fechaRegistro\":\"2025-06-01\",\"activo\":true,\"solicitudes\":[]}"
call :api POST "/api/v1/proveedor" "{\"nombre\":\"Importadora de Libros Ltda\",\"rut\":\"77.987.654-3\",\"direccion\":\"Calle Comercio 321\",\"telefono\":\"+56224445555\",\"email\":\"info@importadora.cl\",\"fechaRegistro\":\"2025-06-15\",\"activo\":true,\"solicitudes\":[]}"

call :api POST "/api/v1/descuentos" "{\"nombre\":\"10%% OFF Semanal\",\"fechaVencimiento\":\"2026-12-31\",\"porcentaje\":10,\"cantidad\":3}"

echo   Data seeded.

:: --------------------------------------------------
:: 5. Show summary
:: --------------------------------------------------
echo [5/6] System is up and running!
echo.
echo ================================================
echo   SUMMARY
echo ================================================
echo   Gateway:  http://localhost:8080/swagger-ui.html
echo   Logs:     %LOG_DIR%\
echo.
echo   To stop: close the terminal windows or run:
echo     taskkill /F /IM java.exe
echo ================================================
pause
goto :eof

:api
set "method=%~1"
set "url=%~2"
set "data=%~3"
if defined data (
    curl -s -X %method% "%GW%%url%" -H "Content-Type: application/json" -d "%data%" > nul
) else (
    curl -s -X %method% "%GW%%url%" > nul
)
goto :eof
