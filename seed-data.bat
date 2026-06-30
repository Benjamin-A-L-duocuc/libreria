@echo off
setlocal enabledelayedexpansion

set "BASE_URL=http://localhost:8080"

echo ================================================
echo   Populating sample data via Gateway
echo ================================================
echo.

:: --------------------------------------------------
echo [1/10] CREATING BRANCHES...
:: --------------------------------------------------
call :api POST "/api/sucursales" "{\"idAdminGeneral\":1,\"idGerenteSede\":1,\"nombre\":\"Sucursal Centro\",\"direccion\":\"Av. Principal 123, Santiago\",\"fechaInicio\":\"2025-01-15\",\"telefono\":\"+56212345678\",\"email\":\"centro@libreria.cl\",\"estado\":true}"
echo   Branch Centro created.

call :api POST "/api/sucursales" "{\"idAdminGeneral\":1,\"idGerenteSede\":1,\"nombre\":\"Sucursal Norte\",\"direccion\":\"Calle Norte 456, Antofagasta\",\"fechaInicio\":\"2025-03-01\",\"telefono\":\"+56298765432\",\"email\":\"norte@libreria.cl\",\"estado\":true}"
echo   Branch Norte created.

:: --------------------------------------------------
echo [2/10] REGISTERING USERS...
:: --------------------------------------------------
call :api POST "/api/v1/usuarios" "{\"nombreCompleto\":\"Carlos Admin\",\"email\":\"carlos@libreria.cl\",\"password\":\"Admin123!\",\"tipo\":\"AdministradorGeneral\"}"
call :api POST "/api/v1/usuarios" "{\"nombreCompleto\":\"Maria Cajero\",\"email\":\"maria@libreria.cl\",\"password\":\"Cajero123!\",\"tipo\":\"Cajero\"}"
call :api POST "/api/v1/usuarios" "{\"nombreCompleto\":\"Juan Perez\",\"email\":\"juan@email.cl\",\"password\":\"Cliente1!\",\"tipo\":\"Cliente\"}"
call :api POST "/api/v1/usuarios" "{\"nombreCompleto\":\"Ana Silva\",\"email\":\"ana@email.cl\",\"password\":\"Cliente2!\",\"tipo\":\"Cliente\"}"
echo   Users registered.

:: --------------------------------------------------
echo [3/10] CREATING BOOKS...
:: --------------------------------------------------
call :api POST "/api/libros" "{\"nombre\":\"Cien Anios de Soledad\",\"descripcion\":\"Novela del realismo magico\",\"editorial\":\"Sudamericana\",\"autor\":\"Gabriel Garcia Marquez\",\"precioCompra\":5000,\"precioVenta\":15000,\"categoria\":\"FICCION\",\"fechaCreacion\":\"2026-01-15\"}"
call :api POST "/api/libros" "{\"nombre\":\"Breve Historia del Tiempo\",\"descripcion\":\"Divulgacion cientifica\",\"editorial\":\"Bantam Books\",\"autor\":\"Stephen Hawking\",\"precioCompra\":7000,\"precioVenta\":12000,\"categoria\":\"CIENCIA_FICCION\",\"fechaCreacion\":\"2026-01-15\"}"
call :api POST "/api/libros" "{\"nombre\":\"1984\",\"descripcion\":\"Distopia clasica\",\"editorial\":\"Secker and Warburg\",\"autor\":\"George Orwell\",\"precioCompra\":4000,\"precioVenta\":10000,\"categoria\":\"FICCION\",\"fechaCreacion\":\"2026-01-15\"}"
call :api POST "/api/libros" "{\"nombre\":\"El Principito\",\"descripcion\":\"Literatura infantil\",\"editorial\":\"Reynal and Hitchcock\",\"autor\":\"Antoine Saint-Exupery\",\"precioCompra\":3000,\"precioVenta\":8000,\"categoria\":\"INFANTIL\",\"fechaCreacion\":\"2026-01-15\"}"
call :api POST "/api/libros" "{\"nombre\":\"Clean Code\",\"descripcion\":\"Buenas practicas de programacion\",\"editorial\":\"Prentice Hall\",\"autor\":\"Robert C. Martin\",\"precioCompra\":12000,\"precioVenta\":25000,\"categoria\":\"TECNOLOGIA\",\"fechaCreacion\":\"2026-01-15\"}"
echo   Books created.

:: --------------------------------------------------
echo [4/10] ASSIGNING STOCK...
:: --------------------------------------------------
:: Note: Update IDs below after running to match actual IDs
:: Using placeholder IDs: Centro=1, Norte=2, Books=1-5
call :api POST "/api/stock-libros" "{\"idLibro\":1,\"idSucursal\":1,\"stock\":20,\"stockMinimo\":5,\"stockMaximo\":100}"
call :api POST "/api/stock-libros" "{\"idLibro\":2,\"idSucursal\":1,\"stock\":15,\"stockMinimo\":5,\"stockMaximo\":50}"
call :api POST "/api/stock-libros" "{\"idLibro\":3,\"idSucursal\":1,\"stock\":10,\"stockMinimo\":3,\"stockMaximo\":80}"
call :api POST "/api/stock-libros" "{\"idLibro\":4,\"idSucursal\":1,\"stock\":30,\"stockMinimo\":10,\"stockMaximo\":120}"
call :api POST "/api/stock-libros" "{\"idLibro\":5,\"idSucursal\":1,\"stock\":8,\"stockMinimo\":2,\"stockMaximo\":30}"
echo   Stock assigned to Centro.

:: --------------------------------------------------
echo [5/10] CREATING PROVIDERS...
:: --------------------------------------------------
call :api POST "/api/v1/proveedor" "{\"nombre\":\"Distribuidora Cultural SPA\",\"rut\":\"76.123.456-7\",\"direccion\":\"Av. Providencia 789\",\"telefono\":\"+56222223333\",\"email\":\"ventas@cultural.cl\",\"fechaRegistro\":\"2025-06-01\",\"activo\":true,\"solicitudes\":[]}"
call :api POST "/api/v1/proveedor" "{\"nombre\":\"Importadora de Libros Ltda\",\"rut\":\"77.987.654-3\",\"direccion\":\"Calle Comercio 321\",\"telefono\":\"+56224445555\",\"email\":\"info@importadora.cl\",\"fechaRegistro\":\"2025-06-15\",\"activo\":true,\"solicitudes\":[]}"
echo   Providers created.

:: --------------------------------------------------
echo [6/10] CREATING DISCOUNTS...
:: --------------------------------------------------
call :api POST "/api/v1/descuentos" "{\"nombre\":\"10%% OFF Semanal\",\"fechaVencimiento\":\"2026-12-31\",\"porcentaje\":10,\"cantidad\":3}"
echo   Discounts created.

:: --------------------------------------------------
echo [7/10] CREATING IN-STORE SALE...
:: --------------------------------------------------
call :api POST "/api/v1/ventas/crear" "{\"idSucursal\":1,\"idCliente\":3}"
:: Add products & finalize would go here with actual IDs

echo.
echo ================================================
echo   SAMPLE DATA INSERTED!
echo ================================================
echo   Gateway: http://localhost:8080/swagger-ui.html
echo.
echo   NOTE: Update IDs in seed-data.bat after first run
echo   to match the auto-generated IDs.
echo ================================================
goto :eof

:api
set "method=%~1"
set "url=%~2"
set "data=%~3"
if defined data (
    curl -s -X %method% "%BASE_URL%%url%" -H "Content-Type: application/json" -d "%data%" > nul
) else (
    curl -s -X %method% "%BASE_URL%%url%" > nul
)
goto :eof
