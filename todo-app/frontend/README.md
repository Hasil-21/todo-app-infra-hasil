# Frontend — Simple Todo App (React + Vite)

Two pages behind a simple login (no tokens — just in-memory state):

1. **Add Task** (`/add`) — title, description, status dropdown, Add button
2. **View Tasks** (`/tasks`) — list of tasks, mark complete, delete

Built with **Vite** instead of Create React App — CRA's `react-scripts`
is unmaintained and breaks on newer Node versions (e.g. Node 24). Vite
is actively maintained and has no such issues.

## Setup

```bash
npm install
cp .env.example .env    # point VITE_API_URL at your backend
npm run dev
```

Runs on `http://localhost:3000` (same port CRA used). Login with the
seeded user: `admin / admin123`.

## Build for production

```bash
npm run build      # outputs to dist/ (Vite's default, instead of CRA's build/)
npm run preview    # locally preview the production build
```

## Where AWS fits later

- Host the production build (`npm run build` → `dist/`) on **S3 + CloudFront**
- Point `VITE_API_URL` at your **API Gateway** invoke URL once the
  backend moves to Lambda, or at your **ALB** DNS name if it stays on
  EC2
- CodeBuild/CodePipeline can build and push the `dist/` folder to S3
  automatically on every git push

Full mapping is in `AWS-Practice-Guide.md` (shared alongside the three
project folders).
