# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FlecBlog is a modern full-stack blog system with a three-tier architecture:

| Module | Tech Stack | Purpose |
|--------|-----------|---------|
| `server` | Go 1.25 / Gin / GORM / PostgreSQL | Backend API, auth, data management, cron jobs |
| `admin` | Vue 3 / Element Plus / Vite | Admin dashboard, content management, Markdown editor |
| `blog` | Nuxt 4 / Vue 3 / SCSS | Frontend blog, SSR, SEO, PWA |

Additional modules:
- `hub` - Documentation site (Nuxt 3 + Nuxt UI + Tailwind CSS + Content)
- `weapp` - WeChat Mini Program (native miniprogram + TDesign)
- `panel` - Cloudflare Worker proxy (Hono + Wrangler)
- `installer` - CLI installer (Go + Cobra)
- `theme` - Theme templates

## Essential Development Commands

### Server (Go)
```bash
cd server
go mod download                          # Install dependencies
cp .env.example .env                     # Create config
go run cmd/main.go                       # Start dev server
swag init -g cmd/main.go -o docs/        # Regenerate Swagger docs
```

### Admin (Vue 3)
```bash
cd admin
npm install
cp .env.example .env
npm run dev                              # Start dev server (Vite)
npm run build                            # Production build
npm run lint                             # ESLint
npm run type-check                       # vue-tsc type check
```

### Blog (Nuxt 4)
```bash
cd blog
npm install
cp .env.example .env
npm run dev                              # Start dev server (Nuxt SSR)
npm run build                            # Production build
npm run lint                             # ESLint
npm run type-check                       # Nuxt type check
```

### Hub (Docs Site)
```bash
cd hub
npm install
npm run dev                              # Start dev server
npm run build                            # Production build
npm run lint                             # ESLint
npm run typecheck                        # Type check
```

### Docker Deployment
```bash
docker-compose up -d                     # Start all services
docker-compose down                      # Stop all services
```

## Architecture

### Server Layered Architecture
```
server/
├── api/
│   ├── middleware/   # Auth, CORS, logging, rate limiting, RBAC
│   ├── router/       # Route registration
│   └── v1/           # API v1 handlers
├── internal/
│   ├── dto/          # Request/response structs
│   ├── model/        # Database models (GORM)
│   ├── repository/   # Data access layer
│   └── service/      # Business logic layer
├── pkg/              # Shared packages (database, utils, etc.)
├── config/           # Environment config loading
├── templates/        # Email and other templates
└── cmd/main.go       # Entry point
```

Key server patterns:
- Database migrations live in `pkg/database/sql/` as numbered SQL files
- JWT auth via `api/middleware/` — protected routes require valid token
- Swagger annotations on handlers; docs regenerated with `swag init`
- Cron jobs for scheduled tasks (defined in server startup)

### Admin Structure
```
admin/src/
├── api/              # Axios API client modules
├── components/       # Reusable Vue components
├── layouts/          # Page layouts (sidebar, header)
├── router/           # Vue Router config
├── types/            # TypeScript interfaces
├── utils/            # Helpers
└── views/            # Page components
```

### Blog Structure
```
blog/app/
├── components/       # Vue components
├── composables/      # Vue composables (useX functions)
├── layouts/          # Nuxt layouts
├── pages/            # File-based routing
├── plugins/          # Nuxt plugins
└── utils/            # Helpers
```

## Environment Configuration

Each module has its own `.env.example`. Copy to `.env` and edit before running:

- **server**: `JWT_SECRET`, `DB_HOST/PORT/NAME/USER/PASSWORD`, `SERVER_PORT`
- **admin**: `VITE_API_URL` — points to the server API
- **blog**: `NUXT_PUBLIC_API_URL` — points to the server API
- Root `.env.example`: shared vars for Docker Compose (`DB_PASSWORD`, `JWT_SECRET`, `API_URL`)

## Database

PostgreSQL is the only supported database. Migrations are SQL files in `server/pkg/database/sql/` (numbered sequentially). The server auto-applies these on startup.

## Notes

- No test suite currently exists for any module
- Swagger docs are auto-generated — run `swag init` after adding/modifying API endpoints
- The `server` module uses Go modules, not a monorepo tool
