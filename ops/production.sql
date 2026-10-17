SELECT EXISTS(SELECT 1 FROM public.users WHERE email=:'admin_email' AND role='admin' AND banned=false AND deleted_at IS NULL) AS operator_ready \gset
\if :operator_ready
SELECT 'Administrador de la instancia comprobado' AS resultado;
\else
\echo 'Crear cuenta y reclamar rol administrador durante bootstrap'
\quit 1
\endif
