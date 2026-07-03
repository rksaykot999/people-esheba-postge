# 🇧🇩 People E-Sheba — Super Citizen Platform

A production-level, full-stack, AI-powered citizen services platform for Bangladesh.

## 📁 Project Structure
```
pesheba/
├── frontend/          # React + Vite + Tailwind CSS
│   ├── src/
│   │   ├── components/   layout, ui, admin
│   │   ├── pages/        auth, admin, public pages
│   │   ├── context/      Auth + Language context
│   │   ├── services/     Axios API client
│   │   └── translations/ en.json + bn.json
│   └── package.json
└── backend/           # Node.js + Express + PostgreSQL
    ├── src/
    │   ├── controllers/  auth, user, emergency, blood, donation, job, volunteer, admin
    │   ├── routes/       index.js (all routes)
    │   ├── middleware/   auth, upload, errorHandler
    │   ├── config/       db.js (PostgreSQL pool, Render-ready)
    │   └── utils/        jwt.js, response.js, bool.js
    ├── database/
    │   ├── schema.sql          (legacy MySQL schema, kept for reference)
    │   └── schema.postgres.sql (PostgreSQL schema + seed — use this one)
    └── package.json
```

## 🚀 Setup

### 1. Database (PostgreSQL)
Local:
```bash
createdb people_esheba
psql -d people_esheba -f backend/database/schema.postgres.sql
```
On Render: create a **PostgreSQL** instance from the Render dashboard, then run the
same file against it (see "Deploying to Render" below).

### 2. Backend
```bash
cd backend
cp .env.example .env      # set DATABASE_URL to your Postgres connection string
npm install
npm run dev               # http://localhost:5000
```

### 3. Frontend
```bash
cd frontend
npm install
npm run dev               # http://localhost:5173
```

## ☁️ Deploying to Render

1. **Create the database**: Render dashboard → New → PostgreSQL. Pick a name/region
   and create it. Wait for it to become "Available".
2. **Load the schema**: copy the **External Database URL** shown on the database's
   page, then from your machine run:
   ```bash
   psql "<External Database URL>" -f backend/database/schema.postgres.sql
   ```
3. **Create the web service**: Render dashboard → New → Web Service → connect this
   repo, root directory `backend`, build command `npm install`, start command
   `npm start`.
4. **Set environment variables** on the web service:
   - `DATABASE_URL` → the database's **Internal Database URL** (same-region, faster,
     no SSL hop needed; Render generates this for you)
   - `JWT_SECRET`, `JWT_EXPIRES_IN`, `FRONTEND_URL`, `NODE_ENV=production`
5. Deploy. The API will connect to Postgres automatically — `src/config/db.js`
   detects Render/production and enables SSL as needed.


## 🔑 Default Admin
- **Email:** admin@esheba.bd
- **Password:** Admin@1234
- **Route:** /admin

## ✨ Features
- 🔐 JWT Authentication + Role-based access (user/admin)
- 🌐 Bilingual: English ↔ Bangla toggle
- 🚨 Emergency services with SOS modal (999, 199, etc.)
- 🩸 Blood donor registry with availability toggle
- ❤️  Donation/help request system with progress tracking
- 💼 Job portal with applications + resume upload
- 🙌 Volunteer network registration
- 🤖 AI Chatbot assistant (NLP keyword routing)
- 📊 Full Admin Dashboard with Recharts analytics
- 👥 User management (block/unblock/delete/role change)
- 📢 Broadcast notifications to all users
- 🗺️  Map page (plug in Google Maps API key)
- 📱 Mobile-first responsive design
- 🌓 Dark theme throughout

## 🗺️ API Endpoints
| Method | Route | Auth |
|--------|-------|------|
| POST | /api/auth/register | Public |
| POST | /api/auth/login | Public |
| GET  | /api/auth/me | Protected |
| GET  | /api/emergency | Public |
| GET  | /api/blood-donors | Public |
| GET  | /api/donations | Public |
| GET  | /api/jobs | Public |
| GET  | /api/volunteers | Public |
| GET  | /api/admin/dashboard | Admin |
| ... | ... | ... |

md jumman
RK Saykot
md saif