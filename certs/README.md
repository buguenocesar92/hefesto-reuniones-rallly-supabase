Guardar la CA real del proyecto Supabase como ca.crt, legible por el proceso no root de Rallly. No se incluye certificado ficticio.
La CA o bundle debe validar el certificado del hostname elegido, incluido el pooler si se usa; no asumir que una CA de otro endpoint sirve para ambos.
