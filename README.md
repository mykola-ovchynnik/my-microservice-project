# Django + PostgreSQL + Nginx with Docker Compose

This branch contains a minimal Django project that runs in Docker. It consists of three services managed through `docker-compose.yml`:

- **web** – a Django 4.2 application using Python 3.10.
- **db** – a PostgreSQL 14 database.
- **nginx** – a lightweight Nginx instance that proxies requests to Django.

All services are preconfigured to work together so you can bring up the stack with one command.

## What was done

1. Created a Django project (`my_app`) with default settings.
2. Added a `Dockerfile` for the Django service that installs dependencies from `requirements.txt` and starts the development server.
3. Wrote a `docker-compose.yml` describing the `web`, `db` and `nginx` services.
4. Added an example environment file (`.env.example`) for database connection variables.
5. Provided an Nginx configuration (`nginx/default.conf`) that forwards traffic to the Django container.

## Getting started

1. **Clone** this repository and switch to this branch.
2. **Create a `.env` file** in the project root based on `.env.example` and fill in your PostgreSQL credentials. For local development you can use:

```bash
cp .env.example .env
```

3. **Build and start** all containers:

```bash
docker-compose up -d
```

4. Open [http://localhost](http://localhost) in your browser. Django should be running behind Nginx and connected to PostgreSQL.

To stop the stack run `docker-compose down`.

