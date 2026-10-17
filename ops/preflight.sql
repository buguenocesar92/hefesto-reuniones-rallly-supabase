DO $$
DECLARE v integer; r text;
BEGIN
  v := current_setting('server_version_num')::int / 10000;
  IF v NOT IN (16,17) THEN RAISE EXCEPTION 'Validar version PostgreSQL: paquete admite16/17'; END IF;
  IF current_user <> 'rallly_app' THEN RAISE EXCEPTION 'Usar rol rallly_app'; END IF;
  IF NOT has_schema_privilege(current_user,'public','USAGE') OR NOT has_schema_privilege(current_user,'public','CREATE') THEN
    RAISE EXCEPTION 'Faltan permisos del esquema';
  END IF;
  IF EXISTS(SELECT 1 FROM pg_tables WHERE schemaname='public' AND tableowner <> 'rallly_app') THEN
    RAISE EXCEPTION 'Hay tablas de otro propietario; usar proyecto exclusivo';
  END IF;
  IF EXISTS(SELECT 1 FROM pg_tables WHERE schemaname='public') AND
    (to_regclass('public.users') IS NULL OR to_regclass('public.polls') IS NULL) THEN
    RAISE EXCEPTION 'Base no vacia sin marcadores Rallly; revisar antes de migrar';
  END IF;
  IF NOT EXISTS(SELECT 1 FROM pg_extension e JOIN pg_namespace n ON n.oid=e.extnamespace WHERE e.extname='citext' AND n.nspname='public') THEN RAISE EXCEPTION 'Instalar citext en public mediante SQL administrador'; END IF;
  IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname=current_user AND (rolsuper OR rolcreaterole OR rolcreatedb OR rolreplication OR rolbypassrls OR rolinherit)) THEN RAISE EXCEPTION 'Rol app con privilegios excesivos'; END IF;
  FOREACH r IN ARRAY ARRAY['anon','authenticated'] LOOP
    IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname=r) AND EXISTS(
      SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='public' AND c.relkind IN ('r','p') AND has_table_privilege(r,c.oid,'SELECT,INSERT,UPDATE,DELETE')
    ) THEN RAISE EXCEPTION 'Tablas accesibles por rol API %',r; END IF;
  END LOOP;
END $$;
SELECT 'Preflight de permisos y base completado' AS resultado;
