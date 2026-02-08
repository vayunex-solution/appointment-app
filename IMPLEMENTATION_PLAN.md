# Appointment Management System - Implementation Plan

## 🎯 Project Overview

**Objective:** Build a full-stack Appointment Booking System with:
- Service Provider registration & management
- Customer booking flow
- Wallet & payment integration
- Admin dashboard

---

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Flutter)                        │
├─────────────────┬─────────────────┬─────────────────────────────┤
│  Customer App   │  Provider App   │      Admin Dashboard        │
└────────┬────────┴────────┬────────┴──────────────┬──────────────┘
         │                 │                       │
         └─────────────────┼───────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                     BACKEND (Node.js/Express)                    │
├─────────────────────────────────────────────────────────────────┤
│  Auth API  │  Service API  │  Booking API  │  Wallet API  │ Admin│
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   DATABASE (MySQL)                               │
│              vayunexs_db_appointment_booking                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology | Reason |
|-------|------------|--------|
| **Frontend** | Flutter | Cross-platform (Android, iOS, Web) |
| **Backend** | Node.js + Express | Fast, scalable, easy to deploy |
| **Database** | MySQL | User-specified, reliable, ACID compliant |
| **Auth** | JWT + SMTP verification | Secure, email-based verification |
| **Payments** | Razorpay/PayU | UPI, Cards, NetBanking support |

---

## 📁 Database Schema

### Core Tables

```sql
-- Users (Both Customers & Providers)
users (
  id, name, email, mobile, password_hash,
  role ENUM('customer', 'provider', 'admin'),
  is_verified, is_blocked, device_id,
  created_at, updated_at
)

-- Service Providers (Extended Profile)
providers (
  id, user_id, shop_name, category, location,
  is_approved, wallet_balance,
  created_at, updated_at
)

-- Services
services (
  id, provider_id, service_name, category,
  rate, duration_minutes, description,
  is_active, created_at
)

-- Appointments
appointments (
  id, customer_id, provider_id, service_id,
  token_number, booking_date, slot_time,
  status ENUM('pending', 'confirmed', 'completed', 'cancelled'),
  locked_price, created_at
)

-- Wallet Transactions
wallet_transactions (
  id, user_id, type ENUM('credit', 'debit'),
  amount, reference_id, notes, created_at
)

-- Login Audit Logs
login_logs (
  id, user_id, ip_address, device_info,
  status ENUM('success', 'failed'), created_at
)
```

---

## 🚀 Development Phases

### Phase 1: Authentication & User Management (Week 1-2)
| Task | Description |
|------|-------------|
| User Registration | Customer & Provider signup with email verification |
| Email Verification | SMTP integration for OTP/link verification |
| Login System | Email/Mobile + Password login |
| JWT Tokens | Secure session management |
| Password Reset | Email-based password recovery |
| Device Binding | Track device_id for security |

**APIs:** `/auth/register`, `/auth/verify-email`, `/auth/login`, `/auth/forgot-password`

---

### Phase 2: Service Provider Portal (Week 3-4)
| Task | Description |
|------|-------------|
| Provider Dashboard | View profile, services, bookings |
| Service CRUD | Add/Edit/Delete services |
| Availability Setup | Set working hours & slots |
| Admin Approval | Wait for approval before going live |

**APIs:** `/provider/profile`, `/provider/services`, `/provider/bookings`

---

### Phase 3: Customer App & Booking (Week 5-6)
| Task | Description |
|------|-------------|
| Browse Providers | Search by category, location |
| View Services | See provider's services & rates |
| Book Appointment | Select service, date, time slot |
| Token Generation | Auto-generate booking token |

**APIs:** `/providers`, `/providers/:id/services`, `/bookings`

---

### Phase 4: Wallet & Payments (Week 7-8)
| Task | Description |
|------|-------------|
| Wallet Balance | Show balance for providers |
| Add Money | UPI/Card/NetBanking integration |
| Transaction History | Credit/Debit logs |
| Invoice Generation | PDF invoice for bookings |

**APIs:** `/wallet/balance`, `/wallet/add`, `/wallet/transactions`

---

### Phase 5: Admin Dashboard (Week 9-10)
| Task | Description |
|------|-------------|
| Provider Approval | Approve/Reject new providers |
| User Management | Block/Unblock users |
| Reports | Bookings, Revenue, User stats |
| Audit Logs | View all system actions |

**APIs:** `/admin/providers/pending`, `/admin/users/:id/block`, `/admin/reports`

---

### Phase 6: Security & Polish (Week 11-12)
| Task | Description |
|------|-------------|
| Rate Limiting | Prevent brute force attacks |
| IP Tracking | Log IP addresses |
| Failed Login Policy | Block after 5 failed attempts |
| SSL/TLS | HTTPS everywhere |
| Push Notifications | Booking reminders |

---

## ⚠️ Security Checklist
- [x] Email verification required
- [x] Device binding enabled
- [x] Login audit logging
- [x] Failed login blocking (5 attempts → 30 min block)
- [x] Fraud detection with admin review
- [x] SSL/TLS required
- [x] No hardcoded secrets (.env files only)

---

## 📋 User Review Required

> [!IMPORTANT]
> **Decisions Needed:**
> 1. **Backend hosting:** cPanel ya Cloud (AWS/DigitalOcean)?
> 2. **Payment gateway:** Razorpay ya PayU?
> 3. **Start with:** Flutter app pehle ya Backend pehle?

> [!WARNING]
> **Ye project complex hai:**
> - Estimated time: 10-12 weeks (full-time)
> - Payment integration requires business verification

---

**Reply karo:**
- Plan theek hai? (Haan/Nahi)
- Backend hosting preference? (cPanel/Cloud)
- Flutter app pehle ya Node.js backend pehle?
