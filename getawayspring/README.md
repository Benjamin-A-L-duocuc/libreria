# API Gateway

El punto de entrada unico de toda la plataforma. No contiene logica de negocio — solo enruta peticiones HTTP a los microservicios correctos y sirve una documentacion Swagger unificada.

## Que hace

Un cliente (navegador, app movil, Postman) solo necesita conocer **un puerto: 9080**. El gateway examina la URL de cada peticion y la reenvia al microservicio correspondiente. Esto significa que nunca se accede directamente a los puertos 8084, 8092, 8094, etc.

Tambien agrega los Swagger docs de los 9 microservilos en un solo portal de documentacion accesible desde el navegador.

## Configuracion

Todo esta en `src/main/resources/application.yml` — no hay codigo Java custom. Las rutas se definen con prefijos de URL:

| Prefijo de URL | Microservicio destino |
|---------------|----------------------|
| `/api/v1/sesiones/**` | Login (:8092) |
| `/api/v1/usuarios/**` | Registro Usuarios (:8093) |
| `/api/libros/**`, `/api/stock-libros/**`, `/api/reservas/**` | Inventario (:8094) |
| `/api/v1/envios/**` | Envios (:8084) |
| `/api/v1/tienda/**` | TiendaWeb (:8085) |
| `/api/sucursales/**`, `/api/transferencias/**`, `/api/reposiciones/**` | Sucursal (:8086) |
| `/api/v1/ventas/**`, `/api/v1/descuentos/**` | Ventas (:8087) |
| `/api/v1/monitoreo/**` | Monitoreo (:8089) |
| `/api/v1/proveedor/**`, `/api/v1/solicitudes/**` | Proveedores (:8098) |

## Ejecutar

```cmd
cd getawayspring
.\mvnw.cmd spring-boot:run
```

Puerto: **9080** | DB: ninguna | Swagger: `http://localhost:9080/swagger-ui.html`
