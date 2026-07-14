@echo off
setlocal enabledelayedexpansion

set "BASE_DIR=%~dp0"

echo ================================================
echo   Starting all microservices...
echo ================================================
echo.

set "SERVICES=Gateway:9080:getawayspring Login:8092:Login RegistroUsuario:8093:RegistroUsuario Inventario:8094:ms-Inventario Envios:8084:Envios TiendaWeb:8085:TiendaWeb Sucursal:8086:ms-Sucursal Ventas:8087:venta_libro\libro Monitoreo:8089:MoniteoreoGeneral Proveedores:8098:proveedor_libro\libros"

for %%s in (%SERVICES%) do (
    for /f "tokens=1-3 delims=:" %%a in ("%%s") do (
        echo   [%%a] Starting on port %%b...
        start "Libreria-%%a" /D "%BASE_DIR%\%%c" cmd /k ".\mvnw.cmd spring-boot:run"
    )
)

echo.
echo ================================================
echo   All services starting.
echo ================================================
echo.
echo   Gateway ........ http://localhost:9080/swagger-ui.html
echo   Login .......... http://localhost:8092/swagger-ui.html
echo   Registro ....... http://localhost:8093/swagger-ui.html
echo   Inventario ..... http://localhost:8094/swagger-ui.html
echo   Envios ......... http://localhost:8084/swagger-ui.html
echo   TiendaWeb ...... http://localhost:8085/swagger-ui.html
echo   Sucursal ....... http://localhost:8086/swagger-ui.html
echo   Ventas ......... http://localhost:8087/swagger-ui.html
echo   Proveedores .... http://localhost:8098/swagger-ui.html
echo   Monitoreo ...... http://localhost:8089/swagger-ui.html
echo.
echo   To stop: taskkill /F /IM java.exe
echo.
pause
