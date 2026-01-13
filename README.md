# PostgreSQL 18 Slim (Alpine)

Minimal PostgreSQL 18 image for arm64/amd64. ~50MB uncompressed vs ~250MB official.

## Build

```bash
# Single arch
docker build -t postgres:18-slim .

# Multi-arch
docker buildx build --platform linux/amd64,linux/arm64 -t yourrepo/postgres:18-slim --push .
```

## Usage

```bash
# Basic
docker run -d \
  -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:18-slim

# With custom db/user
docker run -d \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_DB=mydb \
  -v pgdata:/var/lib/postgresql/data \
  postgres:18-slim

# Dev mode (no password)
docker run -d \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  postgres:18-slim
```

## Environment Variables

| Variable                    | Default                    | Description                                |
| --------------------------- | -------------------------- | ------------------------------------------ |
| `POSTGRES_PASSWORD`         | -                          | Superuser password (required unless trust) |
| `POSTGRES_USER`             | `postgres`                 | Superuser name                             |
| `POSTGRES_DB`               | `$POSTGRES_USER`           | Default database                           |
| `POSTGRES_HOST_AUTH_METHOD` | -                          | Set to `trust` for no password             |
| `PGDATA`                    | `/var/lib/postgresql/data` | Data directory                             |

## Init Scripts

Mount `.sh` or `.sql` files to `/docker-entrypoint-initdb.d/` for first-run initialization.

## What's Removed vs Official

- Locale generation (uses C.UTF-8)
- gosu → su-exec (smaller)
- Extensive bash scripting → sh
- Doc/man pages
- Contrib modules (add if needed: `postgresql18-contrib`)
