# Aceptación en VPS
- Compose config --quiet correcto, imágenes compatibles y descarga verificada.
- Preflight con TLS verify-full, rol limitado, proyecto exclusivo y Data API desactivada. citext existe en public sin afectar otros proyectos.
- Migraciones Prisma terminan usando DIRECT_DATABASE_URL con CA y modo estricto; runtime pg funciona con verify-full/sslrootcert. Probar que una CA incorrecta o hostname erróneo hace fallar la conexión: no basta que haya cifrado sin validar identidad.
- Setup localhost/Mailpit: registro solo del INITIAL_ADMIN_EMAIL, acceso por código/enlace y reclamación nativa del rol en /admin-setup. /control-panel accesible al operador y denegado a quien no tenga el rol.
- En base público: registro cerrado, allowlist correcta, login del operador y SMTP real probado. Puertos de prueba retirados; solo app3000 detrás de HTTPS Coolify. Verificar origen/cookies y enlaces correctos.
- Crear votación ficticia, responder desde perfil separado, comprobar visibilidad de otros participantes y edición propia. Probar invitado según política elegida y versión; no asumir que cerrar registro cierra enlaces públicos.
- Revisar hora America/Santiago frente a otra zona y los cambios de horario. Confirmar y trasladar un horario a una agenda de prueba sin duplicar eventos.
- Probar backup y restauración en otro proyecto con salida controlada antes del arranque. Comprobar administrador, sesiones, votaciones/votos y estado de correo pendiente.
- Confirmar que no se requieren imágenes/adjuntos en este alcance: S3 no está configurado. Revisar licencias para ampliar funciones.
