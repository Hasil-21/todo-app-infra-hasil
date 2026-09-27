// Central place for the backend base URL. When you deploy to AWS,
// change VITE_API_URL to your API Gateway invoke URL / ALB DNS name
// in the frontend's .env — no other code needs to change.
const API_URL = import.meta.env.VITE_API_URL || 'http://todo-app-alb-231462298.ap-south-1.elb.amazonaws.com/api';

async function handle(res) {
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.message || 'Request failed');
  }
  return data;
}

export const login = (username, password) =>
  fetch(`/api/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  }).then(handle);

export const getTasks = (page = 1, limit = 10) =>
  fetch(`/api/tasks?page=${page}&limit=${limit}`).then(handle);

export const createTask = (task) =>
  fetch(`/api/tasks`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(task),
  }).then(handle);

export const updateTaskStatus = (id, status) =>
  fetch(`/api/tasks/${id}/status`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status }),
  }).then(handle);

export const deleteTask = (id) =>
  fetch(`/api/tasks/${id}`, { method: 'DELETE' }).then(handle);
