@echo off
setlocal enabledelayedexpansion

set "BASE_DIR=%~dp0"
set "LOG_DIR=%BASE_DIR%logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

echo ================================================
echo   Starting all microservices...
echo ================================================
echo.

call :run_service "Gateway"            8080 "getawayspring"
call :run_service "Login"              8092 "Login"
call :run_service "RegistroUsuario"    8093 "RegistroUsuario"
call :run_service "Inventario"         8094 "ms-Inventario"
call :run_service "Envios"             8084 "Envios"
call :run_service "TiendaWeb"          8085 "TiendaWeb"
call :run_service "Sucursal"           8086 "ms-Sucursal"
call :run_service "Ventas"             8087 "venta_libro\libro"
call :run_service "Proveedores"        8098 "proveedor_libro\libros"
call :run_service "Monitoreo"          8089 "MoniteoreoGeneral"

echo.
echo ================================================
echo   All services starting. Logs in .\logs\
echo ================================================
echo.
echo   Gateway ........ http://localhost:8080/swagger-ui.html
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
echo   To tail a log: type logs\^<name^>.log
echo ================================================
goto :eof

:run_service
set "name=%~1"
set "port=%~2"
set "dir=%BASE_DIR%%~3"
echo [%name%] Starting on port %port%... (%dir%)
start "Libreria-%name%" /D "%dir%" cmd /k ".\mvnw.cmd spring-boot:run"
echo [%name%] Launched.
goto :eof
