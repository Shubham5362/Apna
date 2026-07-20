# Apna Mandla - Local Marketplace MVP

Apna Mandla is a highly scalable, local marketplace application built with modern production-ready backend and frontend architectures.

## Repository Overview

This repository holds both the backend and frontend services:

```text
├── .github/workflows/    # GitHub Actions for CI/CD
├── backend/              # FastAPI & PostgreSQL Backend Application
│   ├── app/              # FastAPI Application Source
│   │   ├── api/          # Endpoints & Routers (Versioned)
│   │   ├── core/         # Core Configurations, DB connections, Exceptions, Logging
│   │   ├── models/       # SQLAlchemy 2.x Database Models
│   │   └── schemas/      # Pydantic v2 Models & Schemas
│   ├── alembic/          # Alembic Migration Scripts
│   ├── Dockerfile        # Backend Production Docker image setup
│   └── requirements.txt  # Python Dependencies
├── frontend/             # Flutter & Material 3 Mobile/Web Application
│   ├── lib/              # Core Flutter Source
│   │   ├── core/         # Routing, State Management & Network layers
│   │   ├── views/        # UI Screen components (Health Dashboard)
│   │   └── main.dart     # Main Application Bootstrap
│   └── pubspec.yaml      # Flutter & Dart dependencies
├── docker-compose.yml    # Main orchestration file (Database, Redis, API)
├── .env.example          # Sample template for environment variables
└── README.md             # This document
```

---

## Technical Stack

### Backend
- **FastAPI**: Fast, asynchronous REST API with Swagger documentation out of the box.
- **PostgreSQL**: Highly-performant relation database.
- **SQLAlchemy 2.x**: Advanced Object-Relational Mapper.
- **Alembic**: Database migrations management.
- **Redis**: High-speed, in-memory caching and session store.
- **Pydantic v2**: Lightning-fast, typed data validation.
- **JWT-ready architecture**: Pre-integrated JWT utilities ready for user auth.
- **Docker & Compose**: Simple multi-container local and production execution.

### Frontend
- **Flutter & Dart**: Multi-platform development (Android, iOS, macOS, Web, Windows, Linux).
- **Material 3**: Modern, beautiful system designs out of the box.
- **Riverpod**: Robust, safe, compile-time-verified state management.
- **GoRouter**: Clean declarative routing.
- **Dio**: Powerhouse client with interceptors for API calls.

---

## Quick Start (Docker Environment)

To quickly get the backend API, PostgreSQL, and Redis database up and running in a unified Docker cluster:

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Spin up the Docker Compose cluster:**
   ```bash
   docker compose up --build -d
   ```

3. **Verify running containers:**
   ```bash
   docker compose ps
   ```

4. **Run Alembic Migrations:**
   ```bash
   docker compose exec backend alembic revision --autogenerate -m "Initial schema"
   docker compose exec backend alembic upgrade head
   ```

---

## Endpoint References

Once started, the following services and endpoints are active:

- **Welcome Route**: [http://localhost:8000/](http://localhost:8000/)
- **Swagger Documentation**: [http://localhost:8000/api/v1/docs](http://localhost:8000/api/v1/docs)
- **Health Check Endpoint**: [http://localhost:8000/api/v1/health](http://localhost:8000/api/v1/health) (Checks database and Redis connections)

---

## Local Development Setup

### Backend (Local Python Environment)
1. Navigate into backend and create a virtual environment:
   ```bash
   cd backend
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run local server:
   ```bash
   uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
   ```

### Frontend (Local Flutter Setup)
1. Ensure you have the Flutter SDK installed and configured.
2. Navigate into frontend:
   ```bash
   cd frontend
   ```
3. Get packages:
   ```bash
   flutter pub get
   ```
4. Run application:
   ```bash
   flutter run -d chrome  # or your preferred device
   ```
