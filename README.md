# brokenance

A personal finance app built with Flutter. Simple, fast and good-looking, with a clean, minimal interface inspired by Apple and Tesla: lots of space, soft animations, and both dark and light mode.

The goal is to give you a clear picture of your money at a glance: what you have, what you spend, what you save, and what you are saving for.

> Status: the backend API is complete. The Flutter app is being built (setup done).

---

## Features

### Authentication
The app is made for personal use, but it has a login with a username and password. Your data is tied to your account, and you stay logged in when you close and reopen the app.

### Navigation
The app uses a burger menu (drawer) that contains every route in the app, including the profile.

### Dashboard
The home screen. It shows overall information and statistics with charts, for example:
- Current net worth
- Spending by category
- Monthly evolution (income vs. expenses)
- Savings and goals progress

### Profile
- Set and change your first and last name.
- **Net worth**: the money you currently have. You type the starting value and can edit it whenever you need to. After that it updates automatically as money comes in and goes out.
- **Monthly income (company payment)**: a fixed amount, for example `900`. On the **1st day of every month** it is automatically added to your net worth.

### Lists
Each of these sections is a list where every row has **edit** and **delete** actions:

| Route | Meaning |
|---|---|
| Subscrições | Your subscriptions (gym, Netflix, insurance...), charged automatically every month or every year |
| Despesas | Expenses |
| Saídas/Férias | Outings and holidays |
| Lazer | Leisure |
| Poupança | How much you want to save per month. The latest row is your current target, older rows stay as history |
| Objetivos | Goals (save X to buy Y). You update the saved amount by hand, with a quick "add to goal" button on each row |

Items are added through a form where you pick the type, so the item ends up in the right list.

How they affect your net worth:
- **Despesas, Lazer, Saídas/Férias**: you add them by hand when you spend the money, and they subtract from your net worth.
- **Subscrições**: charged automatically on their day (every month, or every year on a day and month), and subtracted from your net worth each time.
- **Poupança and Objetivos**: only track your savings target and goal progress. They do not change your net worth.
- Editing or deleting an item keeps your net worth consistent.

### Appearance
- Dark and light mode
- Available in Portuguese and English
- Minimal UI with smooth animations and polished charts

---

## Tech overview

- **App** (`app/`): Flutter, using BLoC for state management.
- **Backend** (`backend/`): a REST API in Node.js (Express 5), PostgreSQL with Prisma, running in Docker.
  - Layered structure: `routes/`, `controllers/`, `services/`, `views/`, `schemas/` (zod), `docs/`.
  - Auth with username and password (argon2id), short-lived JWT access tokens and rotating refresh tokens.
  - Money is stored as whole cents, so every sum is exact.
  - Monthly income and subscription charges are applied automatically, also for days the app was closed, and never twice.
  - Interactive API documentation (Swagger) at `/docs`.

---

## Getting started

### Backend

Requirements: Docker, and Node.js 22+ to run the tests or the API outside Docker.

```sh
cd backend
cp .env.example .env     # then fill in the empty values (database and JWT secret)
npm install
docker compose up -d     # API on http://localhost:3000 and PostgreSQL
```

- API documentation: http://localhost:3000/docs
- Tests: `npm test` (needs the database: `docker compose up -d db`)
- Forgotten password: `docker compose exec api npm run user:reset-password -- <username>`
- Production: `docker compose -f docker-compose.prod.yml up -d --build`, behind an HTTPS reverse proxy

### App

Instructions will be added once the app is built.

---

## Roadmap

- [x] Define requirements and structure
- [x] Backend API and Docker setup (auth, profile, lists, subscriptions, dashboard)
- [x] Scaffold the Flutter app: theme (light/dark), PT/EN translations, drawer and routes, API client
- [x] Login, register, staying logged in, logout and session expiry
- [ ] Profile (name, net worth, monthly income)
- [ ] Lists with add/edit/delete
- [ ] Dashboard with charts
- [ ] Connect the app to the API
