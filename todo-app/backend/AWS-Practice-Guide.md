# AWS Practice Guide — Simple Todo App

This app is deliberately basic (2 pages, 4 endpoints, 2 tables) so the
*app logic* stays out of your way. The point is to layer AWS services
around it in phases, in a real-project shape rather than isolated
tutorials. Order matters less than making sure each phase actually
works end-to-end before moving on — same approach you used for TaskApi.

---

## Phase 1 — Baseline on plain EC2 (sanity check)

Before touching managed services, get the 3 pieces talking to each
other on raw infrastructure, so later phases are "replace X" instead
of "build the whole thing from scratch."

| Component | AWS service |
|---|---|
| Database | **RDS for PostgreSQL** (single-AZ to start) in a private subnet |
| Backend | Node/Express on an **EC2** instance in a public/private subnet |
| Frontend | React build served from the same or another EC2, or straight to **S3** |
| Networking | Your existing **VPC** pattern (public/private subnets, NAT Gateway, security groups) |
| Secrets | **Secrets Manager** or **SSM Parameter Store** for the DB credentials instead of a `.env` file |

Validate: browser → EC2 (frontend) → EC2 (backend) → RDS, all inside
your VPC, security groups locked down to only what's needed.

---

## Phase 2 — Serverless the backend

This is where **API Gateway + Lambda** come in, and where your earlier
Lambda-internals learning session (cold starts, warm invocations,
SIGTERM drains) becomes directly relevant.

| Backend route | Lambda function | API Gateway route |
|---|---|---|
| `POST /api/login` | `login-fn` | `POST /login` |
| `GET /api/tasks` | `list-tasks-fn` | `GET /tasks` |
| `POST /api/tasks` | `create-task-fn` | `POST /tasks` |
| `PATCH /api/tasks/:id/status` | `update-status-fn` | `PATCH /tasks/{id}/status` |
| `DELETE /api/tasks/:id` | `delete-task-fn` | `DELETE /tasks/{id}` |

Key practice points:
- Each Express route handler in `backend/routes/` maps almost 1:1 to a
  Lambda — good exercise in splitting a monolith into functions.
- Lambdas need to sit **inside your VPC** to reach RDS privately — this
  is where you'll hit (and learn to fix) the classic Lambda-in-VPC
  cold-start/ENI tradeoffs.
- Use **RDS Proxy** in front of Postgres once Lambda concurrency scales
  up, so you're not exhausting Postgres connections.
- API Gateway gives you a natural spot to add **usage plans / API
  keys** later, and eventually a **Cognito authorizer** to replace the
  "no auth" login for real.

---

## Phase 3 — Async processing with SQS and SNS

The todo app doesn't *need* async processing, but you can bolt it on
deliberately for practice:

- **SQS**: when `create-task-fn` inserts a task, push a message onto a
  queue (`task-created-queue`). A separate consumer Lambda
  (`process-new-task-fn`) polls the queue and does something trivial
  but real — e.g. writes an audit log row, or a CloudWatch custom
  metric. This gives you a genuine producer/consumer decoupling
  pattern to practice with, including DLQ (dead-letter queue) handling
  for failed messages.
- **SNS**: when `update-status-fn` sets a task to `completed`, publish
  to an SNS topic (`task-completed-topic`). Subscribe an email
  endpoint (or another SQS queue) to it — practice fan-out (one event,
  multiple subscribers) vs SQS's point-to-point model.
- **EventBridge** (optional stretch): route the same "task completed"
  event through EventBridge instead of calling SNS directly from
  Lambda, and use an EventBridge rule to trigger the notification —
  good practice for event-driven architecture patterns beyond simple
  pub/sub.

---

## Phase 4 — CI/CD: CodeBuild + CodePipeline

Since you specifically want a "complex" pipeline here, split it into
one pipeline per layer (mirrors how a real team would separate
frontend/backend/infra ownership):

**Backend pipeline**
1. Source: GitHub (`backend/` folder) via CodeStar connection
2. CodeBuild: install deps, run tests, package Lambda zips (or build a
   Docker image if you go the ECS/Fargate route instead of Lambda —
   you already have that pattern from [[ecs-fargate-pipeline]])
3. Deploy stage: **SAM** or **CloudFormation** (nested stacks, which
   you already learned) to update the Lambda functions + API Gateway,
   or **CodeDeploy** if running on ECS/EC2
4. Add a manual approval action before the production deploy stage —
   good practice for multi-stage pipelines beyond your Jenkins work

**Frontend pipeline**
1. Source: GitHub (`frontend/` folder)
2. CodeBuild: `npm install && npm run build`
3. Deploy: sync `build/` to **S3**, then **CloudFront** invalidation
   step

**Database pipeline (optional, more advanced)**
1. Source: GitHub (`database/` folder)
2. CodeBuild: run `schema.sql` (or a proper migration tool like
   Flyway/node-pg-migrate) against RDS using credentials pulled from
   Secrets Manager at build time — practice safely injecting secrets
   into CodeBuild instead of hardcoding them

Combine all three into one **CodePipeline** with parallel actions for
frontend/backend and a sequential gate for the DB migration to run
first — this "complex pipeline" shape (parallel + sequential +
approval gates) is the part worth practicing deliberately.

---

## Phase 5 — Alternative compute paths (pick based on what you want more reps on)

You've already done ECS Fargate ([[ecs-fargate-pipeline]]) and EKS
([[order-service-eks-practical]]) elsewhere — you can re-run this same
todo app through either path instead of Lambda, as a variant:

- **ECS Fargate**: containerize `backend/` with a Dockerfile, deploy
  behind an ALB, reuse your existing multi-environment pipeline
  pattern.
- **EKS**: same containerized backend, deployed via Terraform + IRSA +
  ALB Ingress like your order-service project — a good comparison
  exercise between "same app, three different compute models"
  (EC2 → Lambda → EKS).

---

## Phase 6 — Observability and hardening

Once the pieces are up, close the loop with what you already know:
- **CloudWatch** dashboards + alarms on Lambda errors/duration, RDS
  CPU/connections, SQS queue depth
- **CloudTrail** + **EventBridge** rule to alert on IAM changes
- **WAF** in front of API Gateway/CloudFront
- **GuardDuty** enabled at the account level
- Multi-AZ RDS + automated backups once you're comfortable with the
  single-AZ version

---

## Suggested order given your background

Given you've already done Jenkins HA, CloudFormation, ECS Fargate, and
EKS, the highest-leverage *new* reps here are:
1. RDS + Lambda + API Gateway (Phase 1–2) — you have theory
   (Lambda internals) but not much hands-on API Gateway + RDS-in-VPC yet
2. SQS + SNS (Phase 3) — flagged in your own notes as "practiced with
   Serverless Framework" but not in a real multi-service app
3. The combined CodePipeline (Phase 4) — your CI/CD reps so far are
   Jenkins-based; a CodePipeline/CodeBuild version fills that gap
4. ECS/EKS variant (Phase 5) is optional — you already have solid reps
   there from other projects, so treat it as reinforcement, not priority
