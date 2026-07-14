@echo off
setlocal enabledelayedexpansion

set "BASE_DIR=%~dp0"
set "GW=http://localhost:9080"
set "PORTS=9080 8092 8093 8094 8084 8085 8086 8087 8089 8098"

REM --------------------------------------------------
REM  --clean: drop all tables via MySQL
REM --------------------------------------------------
set "CLEAN_MODE=0"
if /i "%~1"=="--clean" set "CLEAN_MODE=1"

if %CLEAN_MODE% equ 1 (
    echo.
    echo  ATENCION: Se borraran TODOS los datos existentes.
    echo  Bases afectadas: inventario_ms, login_usuario, registro_usuario,
    echo  Envio, Tienda_Web, sucursal_ms, ventas, monitoreo_ms, proveedor
    echo.
    set /p "CONFIRM=Continuar? (s/N): "
    if /i not "!CONFIRM!"=="s" (
        echo Cancelado.
        exit /b 0
    )

    where mysql >nul 2>&1
    if errorlevel 1 (
        echo  mysql no encontrado en PATH. Agregue MySQL de XAMPP al PATH.
        echo  Ej: set PATH=C:\xampp\mysql\bin;%%PATH%%
        exit /b 1
    )

    set "DBS=inventario_ms login_usuario registro_usuario Envio Tienda_Web sucursal_ms ventas monitoreo_ms proveedor"
    for %%d in (!DBS!) do (
        echo  Limpiando %%d...
        mysql -u root -N -e "SELECT CONCAT('DROP TABLE IF EXISTS ', table_name, ';') FROM information_schema.tables WHERE table_schema='%%d'" 2>nul | mysql -u root %%d 2>nul
        if errorlevel 1 (echo  SKIP %%d) else (echo  OK %%d)
    )
    echo  Bases limpias.
)

REM --------------------------------------------------
REM  Pre-flight checks
REM -------------------------------------------------=
echo.
java -version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Java no encontrado. Instale JDK 21.
    exit /b 1
)

curl --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: curl no encontrado.
    exit /b 1
)

REM --------------------------------------------------
echo.
echo ================================================
echo       LIBRERIA - DEMO COMPLETA
echo   Iniciando 10 microservicios + datos prueba
echo ================================================
echo.

REM --------------------------------------------------
REM  1) Matar procesos previos en los puertos
REM --------------------------------------------------
echo [1/5] Limpiando procesos previos...
for %%p in (%PORTS%) do call :kill_port %%p
echo  Puertos liberados.

REM --------------------------------------------------
REM  2) Arrancar primeros 9 MS con mvnw.cmd spring-boot:run
REM     (Monitoreo se lanza despues para evitar race condition)
REM --------------------------------------------------
echo [2/5] Iniciando microservicios...

set "FIRST_WAVE=Gateway:9080:getawayspring Login:8092:Login RegistroUsuario:8093:RegistroUsuario Inventario:8094:ms-Inventario Envios:8084:Envios TiendaWeb:8085:TiendaWeb Sucursal:8086:ms-Sucursal Ventas:8087:venta_libro\libro Proveedores:8098:proveedor_libro\libros"

for %%s in (%FIRST_WAVE%) do (
    for /f "tokens=1-3 delims=:" %%a in ("%%s") do (
        echo   [%%a] Starting on port %%b...
        start "Libreria-%%a" /D "%BASE_DIR%\%%c" cmd /k ".\mvnw.cmd spring-boot:run"
    )
)

echo  Primeros 9 servicios lanzados.

REM --------------------------------------------------
REM  3) Esperar primeros 9, luego lanzar Monitoreo
REM --------------------------------------------------
echo [3/5] Esperando que los servicios esten listos...

call :wait_for 9080 Gateway
if errorlevel 1 (
    echo.
    echo  ERROR: Gateway no disponible. Verifique que el submodulo
    echo  getawayspring este correctamente clonado (git submodule update --init).
    pause
    exit /b 1
)
call :wait_for 8092 Login
call :wait_for 8093 Registro
call :wait_for 8094 Inventario
call :wait_for 8084 Envios
call :wait_for 8085 TiendaWeb
call :wait_for 8086 Sucursal
call :wait_for 8087 Ventas
call :wait_for 8098 Proveedores

echo  Ahora lanzando Monitoreo...
start "Libreria-Monitoreo" /D "%BASE_DIR%\MoniteoreoGeneral" cmd /k ".\mvnw.cmd spring-boot:run"
call :wait_for 8089 Monitoreo

echo  Todos los servicios UP.

REM --------------------------------------------------
REM  4) Sembrar datos via Gateway
REM --------------------------------------------------
echo [4/5] Sembrando datos de prueba...
call "%~dp0seed-data.bat"

REM --------------------------------------------------
REM  5) Mostrar resumen
REM --------------------------------------------------
echo [5/5] Resumen del sistema
echo.
echo ================================================
echo            RESUMEN DEL SISTEMA
echo ================================================
echo.
echo  Swagger UI (Gateway): http://localhost:9080/swagger-ui.html
echo  Monitoreo estado:     http://localhost:9080/api/v1/monitoreo/estado
echo.
echo  Sucursales:
curl -sf "%GW%/api/sucursales" 2>nul | findstr /r /c:"nombre" 2>nul
if errorlevel 1 echo   (no disponible)
echo.
echo  Para detener: taskkill /F /IM java.exe
echo.
pause
goto :eof

REM ============================================================
REM  SUBROUTINES
REM ============================================================

:kill_port
set "port=%~1"
for /f "tokens=*" %%a in ('netstat -ano ^| findstr /c:":!port! "') do (
    set "LINE=%%a"
    for %%b in (!LINE!) do set "PID=%%b"
    taskkill /F /PID !PID! >nul 2>&1
)
exit /b 0

:wait_for
set "port=%~1"
set "name=%~2"
for /l %%i in (1,1,60) do (
    curl -sf "http://localhost:!port!/actuator/health" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [OK] !name! ^(port !port!^)
        exit /b 0
    )
    timeout /t 2 /nobreak >nul
)
echo   [FAIL] !name! (port !port!) - TIMEOUT
exit /b 1
