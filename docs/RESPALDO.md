# Respaldo y recuperación
`python3 scripts/backup.py` pausa app, ejecuta pg_dump de public, copia configuración/.env/CA, calcula SHA-256 y escribe completed solo al terminar. Finalmente reinicia app si antes estaba activo. Hay indisponibilidad; no ejecutar a la vez que una migración o despliegue, ni con otra app escribiendo en esa DB.

`python3 scripts/check_backup.py /ruta/respaldo` comprueba producto/versión, archivos y hashes. Los hashes detectan corrupción, no autenticidad; usar copias de confianza. La copia contiene emails, votaciones, sesiones, correo pendiente y secretos. Guardarla cifrada fuera del VPS con acceso restringido y retención acordada.

No incluye S3/R2/Garage, imágenes Docker, DNS/TLS ni configuración de Coolify. En esta entrega no se configura almacenamiento de imágenes, por lo que los datos funcionales previstos están en PostgreSQL. Si se añade otro almacén, ampliar y ensayar el respaldo.

## Restaurar en proyecto nuevo
1. Preparar un proyecto Supabase nuevo y exclusivo con el SQL del kit (incluido citext en public), rol/clave, CA y Data API desactivada. Copiar este mismo kit a carpeta nueva. Mantener app detenida; no ejecutar sus migraciones antes de recuperar datos.
2. Crear .env para destino con sus credenciales DB/CA y conservar SECRET_PASSWORD original del respaldo. No conservar el host de producción por accidente. Revisar inicial-admin/allowlist.
3. Ejecutar `python3 scripts/restore_db.py /ruta/respaldo --accept-restored-mail`. Verifica manifiesto/hash, clave conservada, app detenida y public sin tablas. No borra datos. Restaura sin owner/ACL de origen y en una transacción, conservando el esquema public y la extensión citext ya preparada por administrador.
4. No inicia app automáticamente. Antes de un ensayo, bloquear salida externa salvo DNS y la conexión PostgreSQL al proyecto de prueba. El kit no instala firewall: aplicar y comprobar esa política en el entorno de ensayo. No usar simplemente una red Docker internal, porque bloquearía también Supabase.
5. Usar bootstrap/Mailpit como captura de correo adicional, sin asumir que eso sustituye el control de salida. Una DB recuperada puede contener correo pendiente y sesiones; revisar su estado antes de iniciar el servicio. No enviar invitaciones recuperadas a clientes sin revisar y autorizar.
6. Probar login desde un perfil limpio, administrador, votaciones, respuestas y horarios. No permitir dispositivos de producción sobre una copia hasta revisar el corte; no operar ambos sistemas sobre la misma DB.

Actualización: respaldo primero, revisar versión/notas y cambiar tag/digest juntos en copia de ensayo. No asumir que una imagen antigua puede leer datos migrados por una nueva. Conservar kit y copia de la misma versión para revertir de forma comprobada.
