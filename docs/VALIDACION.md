# Validación · 2026-10-16
Realizado localmente:
- Sintaxis Python por AST, shell con sh -n, YAML de ambos Compose y sintaxis Node del guard.
- Imágenes fijadas por digest, sin puertos publicados en Compose base, registro público cerrado.
- configure.py crea .env0600, genera dos secretos diferentes y rechaza sobrescritura.
- Guard Node ejecutado en una VM con solo la presencia del archivo CA simulada: admite bootstrap localhost y rechaza TLS desactivado en runtime, sslaccept no estricto en migración, allowlist vacía, secreto corto y publicación sin SMTP_READY.
- Con comandos Docker simulados: pausa/dump/reinicio, manifiesto/checksums, filtrado de SCHEMA public y entradas de extensión citext en la lista de pg_restore; rechazo de DB ocupada, SECRET_PASSWORD cambiado o archivo manipulado. Reinicio tras fallo de dump y completed solo en copia terminada.
- Integridad ZIP; sin .env real, CA real, respaldos ni cachés.

No se ejecutó Docker, PostgreSQL, Supabase, Prisma, Next.js, SQL de preparación, SMTP ni navegador. Los dumps eran archivos ficticios: no prueban pg_restore, permisos o tipos citext reales. Los tests del guard validan parámetros, no cadena/hostname TLS ni entrega de correo. Tampoco demuestran cierre de registro, flujo de invitados o panel administrador de la app.

Pendiente: docs/ACEPTACION.md completo en VPS con ambas conexiones y CA reales, prueba negativa de certificado/host, migraciones, administrador, login, políticas de alta/participación, SMTP, HTTPS, horarios y recuperación funcional en proyecto distinto con salida controlada.

No se creó cuenta, votación, evento de calendario ni integración externa y no se envió ningún correo real. Es un kit de despliegue preparado para validar.
