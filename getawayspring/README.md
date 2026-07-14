# API Gateway (getawayspring)

Punto de entrada unico del sistema. Proxy inverso que enruta todas las peticiones HTTP a los microservicios backend. No tiene base de datos propia.

## Puerto

**9080** — Unico puerto expuesto al exterior.

## Rutas

| Destino | Puerto | Predicado |
|---------|--------|-----------|
| Login | 8092 | `/api/v1/sesiones/**` |
| Registro Usuarios | 8093 | `/api/v1/usuarios/**` |
| Inventario | 8094 | `/api/libros/**`, `/api/stock-libros/**`, `/api/reservas/**` |
| Envios | 8084 | `/api/v1/envios/**` |
| TiendaWeb | 8085 | `/api/v1/tienda/**` |
| Sucursal | 8086 | `/api/sucursales/**`, `/api/transferencias/**`, `/api/reposiciones/**` |
| Ventas | 8087 | `/api/v1/ventas/**`, `/api/v1/descuentos/**` |
| Monitoreo | 8089 | `/api/v1/monitoreo/**` |
| Proveedores | 8098 | `/api/v1/proveedor/**`, `/api/v1/solicitudes/**` |

## Ejecucion

```cmd
cd getawayspring
.\mvnw.cmd spring-boot:run
```

## Swagger

Swagger UI esta disponible en la raiz del gateway. Cada microservicio registra su documentacion de API a traves de rutas de agregacion.

## Configuracion

Archivo: `src/main/resources/application.yml`

Spring Cloud Gateway usa rutas declarativas en YAML. No hay codigo Java personalizado — toda la logica de enrutamiento esta en la configuracion.

## Dependencias clave

- `spring-cloud-starter-gateway` (reactivo, WebFlux)
- `springdoc-openapi-starter-webflux-ui`
