# Datos personales — Reuniones (Rallly)

Contrato del kit `hefesto-reuniones-rallly-supabase` bajo la **Ley 21.719** (Proteccion de Datos
Personales, Chile). Este documento es normativo para el kit: el despliegue no
se considera completo sin el.

## 1. Inventario de datos

Rallly guarda **datos personales**: nombre y correo de cada participante, zona horaria, agenda y contenido de las reuniones, respuestas de disponibilidad, reacciones y comentarios. Tambien las votaciones y la lista de administradores (`ALLOWED_EMAILS`).

## 2. Control de acceso y roles

El control de acceso real de Rallly es `ALLOWED_EMAILS`: una lista **nominal** de administradores. El kit rechaza con codigo 3 un valor vacio, con comodin (`*`) o con patron de dominio: el acceso no se concede por coincidencia de correo. `INITIAL_ADMIN_EMAIL` debe estar dentro de la lista.

## 3. Minimizacion

Una reunion necesita nombre, correo y franja horaria. El kit no exige direccion, telefono ni identificacion adicional, y no expone las respuestas de disponibilidad fuera de la propia reunion.

## 4. Retencion

Retencion propuesta: **12 meses** para la agenda y las reacciones, **6 meses** para los registros de auditoria y **7 dias** para el respaldo verificado. El plazo definitivo y la base legal los acuerda el cliente: este documento deja la propuesta marcada para su validacion.

## 5. Supresion, rectificacion y acceso del titular

La supresion de un titular (acceso, rectificacion y supresion) la ejecuta el cliente sobre la base: se anula la cuenta, se eliminan o anonimizan sus reuniones y respuestas, y se documenta la solicitud. El kit no borra datos por su cuenta; garantiza que el respaldo encriptado siga la misma politica y que la restauracion quede auditada.

## 6. Acceso al respaldo, auditoria y transito

`SECRET_PASSWORD` cifra las sesiones: rotarla invalida las sesiones abiertas. No se rota sin aviso y se conserva la del destino al restaurar. El respaldo viaja cifrado y cada restauracion deja `logs/restore-audit.log`.

### Acceso al respaldo y transito

`DB_SSLMODE` por defecto `verify-full` con la CA de Supabase en `certs/`. La publicacion la termina Coolify/Traefik.

## 7. Que NO decide el kit

Los plazos definitivos, la base legal y la incorporacion de los titulares al
registro de actividades de tratamiento son decisiones **del cliente**, no del
kit. Este documento deja la propuesta escrita y verificable; su validacion es
una tarea pendiente de coordinacion.

## 8. Verificacion

```bash
bats tests/                              # ciclo de respaldo con datos sinteticos
python3 scripts/check-env.py --modo real # contrato del .env, sin imprimir valores
python3 scripts/check_backup.py <respaldo>
```
