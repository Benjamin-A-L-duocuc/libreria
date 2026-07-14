# Libreria - Microservicios

Sistema de gestion de libreria basado en microservicios. Administra sucursales, inventario, ventas, envios, proveedores, usuarios y monitoreo del sistema.

## Arquitectura

```
                         ┌─────────────────────┐
                         │   API Gateway :9080  │
                         │   (getawayspring)    │
                         └─────────┬───────────┘
              ┌────────────────────┼─────────────────────┐
              │                    │                     │
    ┌─────────┴──────┐  ┌─────────┴──────┐  ┌──────────┴───────┐
    │  Login :8092   │  │ Registro :8093  │  │  Inventario :8094 │
    │  (sesiones)    │  │ (usuarios)     │  │  (libros+stock)   │
    └────────────────┘  └────────────────┘  └──────────────────┘
              │                    │                     │
    ┌─────────┴──────┐  ┌─────────┴──────┐  ┌──────────┴───────┐
    │  Envios :8084  │  │ TiendaWeb:8085 │  │  Sucursal :8086   │
    └────────────────┘  └────────────────┘  └──────────────────┘
              │                    │                     │
    ┌─────────┴──────┐  ┌─────────┴──────┐  ┌──────────┴───────┐
    │  Ventas :8087  │  │ Monitoreo:8089 │  │  Proveedores     │
    └────────────────┘  └────────────────┘  │  :8098           │
                                            └──────────────────┘
```

Todos los servicios se comunican a traves del **Gateway** en el puerto **9080**. Ningun microservicio se expone directamente al exterior.

## Requisitos

- **JDK 21**
- **XAMPP** (MySQL en puerto 3306)
- **curl** (incluido en Windows 10+)
- **Git** (con soporte para submodulos)

## Instalacion

```cmd
git clone --recursive <url-del-repo>
cd libreria
```

Si ya clonaste sin `--recursive`:
```cmd
git submodule update --init --recursive
```

## Base de datos

Inicia MySQL desde XAMPP y crea las 9 bases de datos vacias:

```sql
CREATE DATABASE IF NOT EXISTS login_usuario;
CREATE DATABASE IF NOT EXISTS registro_usuario;
CREATE DATABASE IF NOT EXISTS inventario_ms;
CREATE DATABASE IF NOT EXISTS Envio;
CREATE DATABASE IF NOT EXISTS Tienda_Web;
CREATE DATABASE IF NOT EXISTS sucursal_ms;
CREATE DATABASE IF NOT EXISTS ventas;
CREATE DATABASE IF NOT EXISTS monitoreo_ms;
CREATE DATABASE IF NOT EXISTS proveedor;
```

Las tablas se crean automaticamente al iniciar cada microservicio (`ddl-auto=update`).

## Inicio rapido

### Opcion 1: Demo completa (servicios + datos de prueba)

```cmd
demo.bat
```

Esto inicia los 10 microservicios, espera que esten listos, y ejecuta `seed-data.bat` para insertar datos de prueba (sucursales, usuarios, libros, stock, proveedores, descuentos, ventas, envios).

Para limpiar la base de datos primero:

```cmd
demo.bat --clean
```

### Opcion 2: Solo servicios (sin datos)

```cmd
run-all.bat
```

### Linux / macOS / WSL

```bash
chmod +x run-all.sh
./run-all.sh

# Con datos de prueba:
chmod +x scripts/demo.sh
./scripts/demo.sh
```

## Datos de prueba

Despues de ejecutar `demo.bat` o `seed-data.bat`, la base contiene:

| Entidad | Cantidad | Detalle |
|---------|----------|---------|
| Sucursales | 2 | Centro (Santiago), Norte (Antofagasta) |
| Usuarios | 4 | Admin, Cajero, 2 Clientes |
| Libros | 5 | Cien Anos de Soledad, 1984, Clean Code, etc. |
| Stock | 10 | 5 libros x 2 sucursales |
| Proveedores | 2 | Distribuidora Cultural, Importadora |
| Descuentos | 3 | 10% OFF (generados automaticamente) |
| Venta | 1 | Presencial, 3 libros, pago en efectivo |
| Envio | 1 | Flujo completo: creado, programado, enviado, recibido |

## Puertos y rutas del Gateway

| Servicio | Puerto | Ruta Gateway |
|----------|--------|-------------|
| API Gateway | 9080 | — |
| Login (sesiones) | 8092 | `/api/v1/sesiones/**` |
| Registro Usuarios | 8093 | `/api/v1/usuarios/**` |
| Inventario (libros+stock) | 8094 | `/api/libros/**`, `/api/stock-libros/**`, `/api/reservas/**` |
| Envios | 8084 | `/api/v1/envios/**` |
| TiendaWeb | 8085 | `/api/v1/tienda/**` |
| Sucursal | 8086 | `/api/sucursales/**`, `/api/transferencias/**`, `/api/reposiciones/**` |
| Ventas + Descuentos | 8087 | `/api/v1/ventas/**`, `/api/v1/descuentos/**` |
| Monitoreo | 8089 | `/api/v1/monitoreo/**` |
| Proveedores | 8098 | `/api/v1/proveedor/**`, `/api/v1/solicitudes/**` |

## Endpoints principales

### Swagger UI

```
http://localhost:9080/swagger-ui.html
```

### Verificacion rapida

```cmd
curl http://localhost:9080/api/v1/monitoreo/estado
```

## Solucion de problemas

| Problema | Solucion |
|----------|----------|
| `curl: (3) Port number was not a decimal number` | PowerShell aliasia `curl` a `Invoke-WebRequest`. Usa `curl.exe` en su lugar. |
| `400 Bad Request` al crear usuarios | Verifica que la DB `registro_usuario` exista y MySQL este corriendo. |
| Gateway no responde | Verifica que el submodulo `getawayspring` este clonado. |
| Puerto 8080 ocupado | Oracle TNS Listener puede usar ese puerto. El gateway usa 9080 por defecto. |
| `taskkill /F /IM java.exe` para detener todo | Cierra todos los procesos Java (todos los microservicios). |
| Tablas duplicadas o corruptas | Ejecuta `demo.bat --clean` para limpiar y recrear. |
