# Hefesto Reuniones · Rallly 4.15.4 + Supabase
Kit nativo para proponer fechas, recoger disponibilidad y coordinar reuniones, talleres o entregas con clientes. Conserva la interfaz y atribución de Rallly. No es una agenda de reservas con cobros ni una réplica de Doodle.

## Stack
Rallly4.15.4 + PostgreSQL en un proyecto Supabase exclusivo. Imágenes fijadas por digest. Se conserva docker-start.sh nativo: exporta AUTH_URL, aplica migraciones Prisma y arranca Next.js. El kit añade comprobaciones de configuración previas y preflight SQL.

Conexiones verificadas preparadas de forma distinta: DATABASE_URL es para el driver Node pg; DIRECT_DATABASE_URL es para Prisma CLI. Ambas usan el mismo host/rol5432 y CA, con sus parámetros TLS propios. No intercambiar sslrootcert de pg con sslcert de Prisma ni desactivar validación para resolver un error. Esta configuración requiere una prueba real de conexión/migraciones en el VPS.

El modelo usa citext para emails; el SQL instala esa extensión en public dentro de un proyecto dedicado. No usar un proyecto que ya tenga citext en otro esquema sin revisar el diseño. No se mueven extensiones de una aplicación existente automáticamente.

Requisitos: Linux, Docker Engine + Compose v2, Python3.11+, dominio HTTPS y SMTP TLS implícito465. Como presupuesto inicial de evaluación, reservar 2GB RAM y 1–2CPU, y medir con la carga prevista. Supabase debe usar PostgreSQL16/17 para las herramientas incluidas.

## Preparar
1. Descomprimir y ejecutar `python3 scripts/configure.py`: crea .env0600, dos secretos diferentes y rechaza sobrescribirlo.
2. Crear proyecto Supabase nuevo y exclusivo. Desactivar su Data API. No se usan Auth, Storage ni REST de Supabase y no se requiere service_role.
3. Ejecutar sql/01-supabase-app.sql como administrador. Crea rallly_app sin permisos administrativos, prepara public y citext y restringe privilegios por defecto. Falla si hay tablas o si citext no queda en public; no borra datos.
4. Asignar a rallly_app la clave DB_PASSWORD mediante `\password rallly_app` en psql administrativo, sin incluirla en un comando/historial SQL. Completar DB_HOST/DB_USER.
5. Usar conexión directa5432; si el VPS carece de IPv6, pooler **Session**5432 y usuario rallly_app.PROJECTREF. No usar Transaction6543 en este kit para migraciones/copias.
6. Descargar CA real del proyecto a certs/ca.crt legible por el usuario no root de Rallly. Marcar SUPABASE_DEDICATED_CONFIRMED y SUPABASE_DATA_API_DISABLED true después de verificarlo. Los scripts no pueden demostrar la opción del panel por sí solos.
7. Completar INITIAL_ADMIN_EMAIL con el correo que administrará la instancia y ALLOWED_EMAILS con ese mismo correo inicialmente. Completar soporte/remitente; no conservar example.invalid. Si un secreto SMTP contiene $ o #, usar el entrecomillado adecuado en .env para Compose y no publicar su salida renderizada.

## Inicio privado y cuenta administradora

```sh
docker compose -f compose.yaml -f compose.bootstrap.yaml config --quiet
docker compose -f compose.yaml -f compose.bootstrap.yaml up -d
```

Abrir túnel `ssh -L 8115:127.0.0.1:8115 -L 8031:127.0.0.1:8031 usuario@servidor`. Visitar http://localhost:8115 y Mailpit en http://localhost:8031. El correo se captura localmente; no llega a personas reales. No publicar estos puertos ni Mailpit.

El bootstrap abre el registro solo para INITIAL_ADMIN_EMAIL. Entrar con ese email, usar el código/enlace capturado en Mailpit y completar el alta. Visitar /admin-setup y reclamar el rol mediante la acción nativa; después comprobar /control-panel. El preflight público exige ese usuario con role=admin, sin bloqueo ni eliminación. No se promociona a nadie con SQL ni se incluyen contraseñas predeterminadas.

Crear una votación ficticia, probar respuestas desde otro perfil y confirmar el horario elegido según docs/FLUJOS.md. El bootstrap tiene red para Supabase y no es un aislamiento total de salida.

## Correo real y Coolify
Configurar PUBLIC_URL HTTPS en dominio raíz, SMTP_HOST, SMTP_USER, SMTP_PASSWORD, soporte y remitente autorizado por el proveedor. Se configura SMTP465 con SMTP_SECURE=true y certificado verificado; no se desactiva TLS. Probar acceso/correo con el proveedor real en privado antes de marcar SMTP_READY=true. Esa marca es una confirmación operativa, no un resultado de test automático.

Importar carpeta/repo privado como recurso Docker Compose de Coolify; elegir **compose.yaml**. Mantener ops/ y certs/ para los montajes relativos. Introducir variables sin versionar .env y validar con config --quiet para no imprimir secretos. Exponer únicamente **app**, puerto **3000**, mediante el dominio HTTPS del proxy. No publicar dbtools/preflight ni puertos del host.

El Compose base cierra REGISTRATION_ENABLED y mantiene ALLOWED_EMAILS. No dejar allowlist vacía. Los permisos de participantes por enlace se rigen por Rallly: probar el flujo real de invitados y qué información queda visible antes de compartirlo con clientes. Para añadir usuarios, revisar las opciones nativas disponibles y su licencia; no abrir registro a todo Internet por comodidad.

Si se pasa desde Compose manual a Coolify, usar respaldo/restauración hacia el proyecto Supabase de destino o verificar explícitamente que se conserva el mismo proyecto autorizado. No levantar dos instancias operativas contra el mismo proyecto sin diseñarlo. Para retirar bootstrap manual, detener con ambos archivos y recrear solo con compose.yaml; verificar que desaparecen los puertos locales y Mailpit.

## Despliegue en Coolify (MVP Hefesto)
Variables nuevas que el compose acepta en `.env` de Coolify para reutilizar
un Postgres compartido del stack (no son obligatorias: el comportamiento
anterior sigue siendo el valor por defecto):

- `DB_NAME` (defecto `postgres`): nombre de la base dentro del Postgres
  compartido. Aparece en `DATABASE_URL` y `DIRECT_DATABASE_URL`.
- `DB_SSLMODE` (defecto `verify-full`): modo TLS del driver Node pg. Para
  Prisma se usa `require` con `sslaccept=strict` salvo que esta variable
  sea `disable`. Con `verify-full` se exige la CA; con otros valores la
  CA no es obligatoria y el DSN omite `sslrootcert`/`sslcert`.
- `DB_SSLROOTCERT`, `DB_SSLCERT` (defecto `/certs/ca.crt`): rutas a la CA.
  Definir como cadena vacía para omitir el parámetro del DSN.
- `DB_ALLOW_INTERNAL_HOST` (defecto `false`): permite hosts que no sean
  `*.supabase.co` en el preflight cuando `DB_SSLMODE=disable`.

El preflight y `validate.cjs` aceptan el arranque con `SMTP_READY=false`
para despliegues sin correo real; el envío queda desactivado hasta que se
configure el proveedor y se marque `SMTP_READY=true`.

`bash scripts/coolify-check.sh` valida que el `compose.yaml` cumple el
contrato Coolify (sin `ports`, `container_name`, `privileged`, `name:`
fijo en raíz/redes/volúmenes, ni `docker.sock`).

## Datos, archivos y límites
Usuarios, votaciones, votos, sesiones y cola de correo están en PostgreSQL. Este kit no configura S3/Garage/R2 ni cargas de imágenes, logos o adjuntos; sus ejemplos usan texto y fechas. No hay volumen local de datos del servicio que sustituya el respaldo DB. Si luego se añade almacenamiento externo, respaldarlo y recuperarlo por separado de forma coherente.

El acceso es nativo por correo; no se activa OAuth, MFA adicional, SSO, IA, pagos, calendarios externos o licencia de funciones de pago. No se oculta la atribución upstream. La imagen incluye por defecto API_BASE_URL para comprobaciones con el servicio de Rallly; no se afirma que funcione sin ninguna comunicación externa.

SECRET_PASSWORD se conserva durante recuperación: no regenerarlo sobre una DB recuperada. Docker y los administradores del host pueden leer el entorno. Los códigos y enlaces de acceso son sensibles; no compartir logs ni capturas de Mailpit con terceros.

## Entrega de Hefesto
Ofrecer instalación, configuración de acceso/correo, diseño del flujo de coordinación y mantenimiento. El horario ganador puede llevarse manualmente al calendario o actividad de Odoo; no se crea una reunión externa automáticamente. Ver docs/INTEGRACIONES.md.

Kit revisado localmente, sin despliegue real ejecutado. Completar docs/ACEPTACION.md antes de operar con clientes. No se ha creado una cuenta, enviado una invitación ni publicado una votación real.
