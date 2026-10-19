# brokenance

A personal finance app built with Flutter. Simple, fast and good-looking, with a clean, minimal interface inspired by Apple and Tesla: lots of space, soft animations, and both dark and light mode.

The goal is to give you a clear picture of your money at a glance: what you have, what you spend, what you save, and what you are saving for.

> Status: the backend API and the Flutter app are complete (Android checked; iOS needs Xcode selected, see below).

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
- **Net worth**: the money you currently have. You type the starting value and can edit it whenever you need to. After that it updates automatically as money comes in and goes out. An eye button hides it (the app remembers your choice).
- **Monthly income (company payment)**: a fixed amount, for example `900`. On the **1st day of every month** it is automatically added to your net worth.

### Lists
Each of these sections is a list where every row has **edit** and **delete** actions:

| Section | What it is |
|---|---|
| Subscriptions | Your subscriptions (gym, Netflix, insurance...), charged automatically every month or every year |
| Expenses | What you spend day to day |
| Outings & holidays | Dinners out, trips and holidays |
| Leisure | Cinema, games, hobbies |
| Savings | How much you want to save per month. The latest row is your current target, older rows stay as history |
| Goals | Save X to buy Y. You update the saved amount by hand, with a quick "add to goal" button on each row |

Every list has an **Add** button, and you swipe a row away to delete it (with an **Undo** for a few seconds).

How they affect your net worth:
- **Expenses, Leisure, Outings & holidays**: you add them by hand when you spend the money, and they subtract from your net worth.
- **Subscriptions**: charged automatically on their day (every month, or every year on a day and month), and subtracted from your net worth each time.
- **Savings and Goals**: only track your savings target and goal progress. They do not change your net worth.
- Editing or deleting an item keeps your net worth consistent.

### Appearance
- Dark and light mode
- Available in Portuguese and English
- Minimal UI with smooth animations and charts
- A logo, app icons and launch screens: a coin cracked in two (broke, but rising)

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

Requirements: Flutter (stable), an iOS simulator or Android emulator, and the backend running.

```sh
cd app
flutter pub get
flutter run
```

On macOS, iOS builds need Xcode selected once: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
More in [app/README.md](app/README.md).

---

## Roadmap

Done:
- [x] Define requirements and structure
- [x] Backend API and Docker setup (auth, profile, lists, subscriptions, dashboard)
- [x] Flutter app setup: theme (light/dark), Portuguese and English translations, drawer and routes, API client
- [x] Login, register, staying logged in, logout and session expiry
- [x] Profile: balance, monthly income, name, change password
- [x] Lists with add/edit/delete: Expenses, Outings & holidays, Leisure, Subscriptions, Savings, Goals
- [x] Dashboard with charts: balance over time, spending by category, income vs spending, goals
- [x] Connect the app to the API
- [x] Security review (dependency audit, proxy-aware rate limit, docs off in production, https-only release builds)
- [x] Hide or show the balance with an eye button
- [x] Logo, app icons and launch screens

Next:
- [ ] Deploy the API (Render for the server, Neon for PostgreSQL) and turn registration off
- [ ] Build the release app pointing to the deployed https address (with its own signing key)
- [ ] Test on an iPhone simulator and a real iPhone (needs Xcode selected, see above)

Ideas for later:
- [ ] Let the user change the time zone or currency (fixed to Europe/Lisbon and EUR today)
- [ ] Notifications before a subscription renews
- [ ] Face ID / fingerprint unlock
- [ ] Load older items in the expense lists (they show the latest 100 for now)
- [ ] Use the app offline
