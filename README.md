# Libreria — Microservicios

## Requisitos

- JDK 21
- XAMPP (MySQL)
- Windows 10+ (curl incluido)

## Puesta en marcha

1. Abre XAMPP y pulsa **Start** en MySQL.

2. Abre phpMyAdmin y crea estas 9 bases de datos:

   ```
   login_usuario
   registro_usuario
   inventario_ms
   Envio
   Tienda_Web
   sucursal_ms
   ventas
   monitoreo_ms
   proveedor
   ```

3. Clona el repositorio con submódulos:

   ```cmd
   git clone --recursive <url-del-repo>
   cd intento2
   ```

4. Ejecuta el script completo (inicia todo + datos de prueba):

   ```cmd
   demo.bat
   ```

5. Abre el navegador en:

   ```
   http://localhost:8080/swagger-ui.html
   ```

Para iniciar solo los servicios sin datos de prueba:

```cmd
run-all.bat
```
