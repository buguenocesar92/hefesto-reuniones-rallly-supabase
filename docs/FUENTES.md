# Fuentes · 2026-10-16
- https://github.com/lukevella/rallly/releases/tag/v4.15.4
- https://github.com/lukevella/rallly/blob/v4.15.4/apps/web/Dockerfile
- https://github.com/lukevella/rallly/blob/v4.15.4/scripts/docker-start.sh
- https://github.com/lukevella/rallly/blob/v4.15.4/packages/database/src/client.ts
- https://github.com/lukevella/rallly/blob/v4.15.4/packages/database/prisma.config.ts
- https://github.com/lukevella/rallly/blob/v4.15.4/packages/database/prisma/models/user.prisma
- https://github.com/lukevella/rallly/blob/v4.15.4/apps/web/src/app/%5Blocale%5D/admin-setup/actions.ts
- https://github.com/lukevella/rallly/blob/v4.15.4/apps/web/src/env.ts
- https://github.com/lukevella/rallly-selfhosted
- https://www.prisma.io/docs/orm/v7/core-concepts/supported-databases/postgresql
- https://www.prisma.io/docs/orm/v6/overview/databases/postgresql (sslaccept/strict del conector CLI)
- https://node-postgres.com/features/ssl
- https://supabase.com/docs/guides/database/connecting-to-postgres

La app4.15.4 usa Prisma7 con adapter-pg para runtime; prisma.config.ts prefiere DIRECT_DATABASE_URL en la CLI. El kit usa dos URI con TLS apropiado para cada camino y conserva el script nativo, sin modificar el código del motor. La compatibilidad con la CA/proveedor reales requiere aceptación; el guard solo valida estructura de parámetros.

Se incluye licencia original de Rallly y se mantiene atribución. Las funciones sujetas a licencia y el almacenamiento S3 opcional no quedan activados por esta entrega.
