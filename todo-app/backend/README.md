# Backend — Simple Todo App (Node + Express)

Plain Express REST API on top of Postgres. No auth/JWT yet — login is
a simple username/password row check.

## Setup

```bash
npm install
cp .env.example .env   # then edit .env with your Postgres details
npm run dev            # or: npm start
```

Server runs on `http://localhost:5000` by default.

## Endpoints

| Method | Path                    | Purpose                              |
|--------|--------------------------|---------------------------------------|
| POST   | `/api/login`             | Check username/password, no token     |
| GET    | `/api/tasks`              | List all tasks                        |
| POST   | `/api/tasks`              | Create a task                         |
| PATCH  | `/api/tasks/:id/status`   | Update a task's status                |
| DELETE | `/api/tasks/:id`          | Delete a task                         |
| GET    | `/health`                 | Health check (useful for ALB/API GW)  |

### Example: create a task
```bash
curl -X POST http://localhost:5000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Learn SQS","description":"Send a message on task create","status":"pending"}'
```

### Example: update status
```bash
curl -X PATCH http://localhost:5000/api/tasks/1/status \
  -H "Content-Type: application/json" \
  -d '{"status":"completed"}'
```

## Where AWS fits later

This code is intentionally plain Node/Express so you can practice
putting AWS pieces *around* it without rewriting business logic:
- Run it as-is on an EC2 instance behind an ALB, **or**
- Split each route handler into its own Lambda behind API Gateway
- Add an SQS message publish in `POST /api/tasks` for async processing
- Add an SNS notification when a task is marked `completed`
- Point `db.js` at RDS Postgres instead of localhost

Full mapping is in `AWS-Practice-Guide.md` (shared alongside the three
project folders).
