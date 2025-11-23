# Django + PostgreSQL + Nginx Microservice

This project is a containerized Django application running with Docker Compose. It consists of three services:

- **django** – Django 4.2 application using Python 3.10-slim
- **db** – PostgreSQL 13 database
- **nginx** – Nginx Alpine serving as reverse proxy

## Project Structure

```
my-microservice-project/
├── docker-compose.yml          # Multi-container orchestration
├── Dockerfile                  # Django service image definition
├── entrypoint.sh              # Startup script with DB wait & migrations
├── manage.py                  # Django management script
├── requirements.txt           # Python dependencies
├── nginx/
│   └── nginx.conf            # Nginx reverse proxy configuration
└── project/
    ├── settings.py           # Django settings with env vars
    ├── urls.py               # URL routing
    ├── wsgi.py               # WSGI application
    ├── asgi.py               # ASGI application
    ├── static/               # Static files directory
    └── templates/
        └── index.html        # Template files
```

## Features

- **Automated Database Setup**: `entrypoint.sh` waits for PostgreSQL to be ready, runs migrations, and collects static files
- **Environment-Based Configuration**: Django settings use environment variables for flexibility
- **Static File Serving**: WhiteNoise integration for efficient static file handling
- **Health Checks**: Database connection verification before Django starts
- **Reverse Proxy**: Nginx forwards requests from port 8080 to Django on port 8000

## Dependencies

- Django 4.2.7
- psycopg2-binary 2.9.7 (PostgreSQL adapter)
- gunicorn 21.2.0 (WSGI server)
- whitenoise 6.6.0 (static file serving)

## Getting Started

1. **Clone the repository**:

```bash
git clone <repository-url>
cd my-microservice-project
```

2. **Build and start all services**:

```bash
docker-compose up -d
```

3. **Access the application**:
   - Nginx proxy: [http://localhost:8080](http://localhost:8080)
   - Django direct: [http://localhost:8000](http://localhost:8000)
   - PostgreSQL: `localhost:5432`

## Docker Services

### Django Service

- Exposes port `8000`
- Mounts current directory to `/app` for development
- Environment variables configured in `docker-compose.yml`
- Runs migrations and collects static files on startup

### PostgreSQL Service

- Exposes port `5432`
- Database: `project`
- User: `myuser`
- Password: `mypassword`
- Persistent volume: `postgres_data`

### Nginx Service

- Exposes port `8080` → port `80` inside container
- Proxies all requests to `django:8000`
- Configuration: `nginx/nginx.conf`

## Management Commands

**Stop all services**:

```bash
docker-compose down
```

**View logs**:

```bash
docker-compose logs -f
```

**Run Django management commands**:

```bash
docker-compose exec django python manage.py <command>
```

**Access Django shell**:

```bash
docker-compose exec django python manage.py shell
```

**Rebuild containers**:

```bash
docker-compose up -d --build
```

## Environment Variables

Database configuration is set directly in `docker-compose.yml`:

- `POSTGRES_DB=project`
- `POSTGRES_USER=myuser`
- `POSTGRES_PASSWORD=mypassword`
- `POSTGRES_HOST=db`
- `POSTGRES_PORT=5432`
- `DEBUG=1`
