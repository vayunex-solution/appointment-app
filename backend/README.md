# Appointment Management System - Backend

## Quick Start

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Configure Environment
```bash
# Copy example env file
cp .env.example .env

# Edit .env with your actual values
```

### 3. Setup Database
1. Create database `vayunexs_db_appointment_booking` in MySQL
2. Run `database.sql` to create tables

### 4. Run Server
```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### Auth
- `POST /api/auth/register/customer` - Customer registration
- `POST /api/auth/register/provider` - Provider registration
- `POST /api/auth/verify-email` - Verify email
- `POST /api/auth/login` - Login
- `POST /api/auth/forgot-password` - Request password reset
- `POST /api/auth/reset-password` - Reset password

### Provider
- `GET /api/provider/profile` - Get profile
- `GET /api/provider/services` - Get services
- `POST /api/provider/services` - Add service
- `PUT /api/provider/services/:id` - Update service
- `DELETE /api/provider/services/:id` - Delete service
- `GET /api/provider/bookings` - Get bookings
- `GET /api/provider/wallet` - Get wallet balance

### Customer
- `GET /api/customer/providers` - Browse providers
- `GET /api/customer/providers/:id` - Get provider details

### Bookings
- `POST /api/bookings` - Create booking
- `GET /api/bookings/my` - My bookings
- `PUT /api/bookings/:id/reschedule` - Reschedule
- `PUT /api/bookings/:id/cancel` - Cancel

### Admin
- `GET /api/admin/providers/pending` - Pending approvals
- `PUT /api/admin/providers/:id/approve` - Approve provider
- `GET /api/admin/users` - All users
- `PUT /api/admin/users/:id/block` - Block user
- `GET /api/admin/reports` - Reports
- `GET /api/admin/logs` - Login logs
