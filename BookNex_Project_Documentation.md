# BookNex - Appointment Management System
## Complete Project Documentation

---

## 📋 Project Overview

**BookNex** is a comprehensive appointment booking system that connects customers with service providers. The system includes a Flutter mobile app and Node.js backend API.

### Technology Stack

| Component | Technology |
|-----------|------------|
| Mobile App | Flutter (Dart) |
| Backend API | Node.js + Express.js |
| Database | MySQL |
| Authentication | JWT Tokens |
| Hosting | cPanel |

---

## 🏗 System Architecture

```mermaid
flowchart TB
    subgraph "Mobile App (Flutter)"
        A[Customer App]
        B[Provider App]
        C[Admin Panel]
    end
    
    subgraph "Backend (Node.js)"
        D[Express API Server]
        E[Auth Middleware]
        F[Route Handlers]
    end
    
    subgraph "Database"
        G[(MySQL Database)]
    end
    
    subgraph "External Services"
        H[SMTP Email]
    end
    
    A --> D
    B --> D
    C --> D
    D --> E
    E --> F
    F --> G
    D --> H
```

---

## 👥 User Roles & Access

```mermaid
graph LR
    subgraph Users
        A[Customer]
        B[Provider]
        C[Admin]
    end
    
    subgraph Customer Features
        A1[Browse Providers]
        A2[Book Appointments]
        A3[View Bookings]
        A4[Cancel Bookings]
    end
    
    subgraph Provider Features
        B1[Manage Profile]
        B2[Add Services]
        B3[Set Availability]
        B4[View Bookings]
    end
    
    subgraph Admin Features
        C1[Approve Providers]
        C2[Manage Users]
        C3[View Reports]
        C4[Audit Logs]
    end
    
    A --> A1
    A --> A2
    A --> A3
    A --> A4
    
    B --> B1
    B --> B2
    B --> B3
    B --> B4
    
    C --> C1
    C --> C2
    C --> C3
    C --> C4
```

---

## 🔐 Authentication Flow

```mermaid
sequenceDiagram
    participant U as User
    participant A as App
    participant S as Server
    participant D as Database
    participant E as Email
    
    U->>A: Enter Registration Details
    A->>S: POST /auth/register
    S->>D: Create User (unverified)
    S->>E: Send OTP Email
    E->>U: OTP Received
    U->>A: Enter OTP
    A->>S: POST /auth/verify-email
    S->>D: Mark User Verified
    S->>A: JWT Token
    A->>U: Login Success!
```

---

## 📅 Booking Flow

```mermaid
sequenceDiagram
    participant C as Customer
    participant A as App
    participant S as Server
    participant P as Provider
    
    C->>A: Browse Providers
    A->>S: GET /customer/providers
    S->>A: Provider List
    C->>A: Select Provider
    A->>S: GET /customer/providers/:id/services
    S->>A: Services List
    C->>A: Select Service & Date
    A->>S: GET /customer/providers/:id/slots
    S->>A: Available Slots
    C->>A: Select Slot & Book
    A->>S: POST /bookings
    S->>S: Generate Token
    S->>A: Booking Confirmed + Token
    A->>C: Show Token Number
```

---

## 🗄 Database Schema

```mermaid
erDiagram
    USERS ||--o{ PROVIDERS : has
    USERS ||--o{ APPOINTMENTS : makes
    PROVIDERS ||--o{ SERVICES : offers
    PROVIDERS ||--o{ APPOINTMENTS : receives
    PROVIDERS ||--o{ AVAILABILITY : sets
    SERVICES ||--o{ APPOINTMENTS : booked
    
    USERS {
        int id PK
        string name
        string email
        string mobile
        string password
        enum role
        boolean is_verified
        boolean is_blocked
    }
    
    PROVIDERS {
        int id PK
        int user_id FK
        string shop_name
        string category
        string location
        text description
        boolean is_approved
    }
    
    SERVICES {
        int id PK
        int provider_id FK
        string name
        text description
        decimal price
        int duration
        boolean is_active
    }
    
    AVAILABILITY {
        int id PK
        int provider_id FK
        int day_of_week
        time start_time
        time end_time
        int slot_duration
    }
    
    APPOINTMENTS {
        int id PK
        int customer_id FK
        int provider_id FK
        int service_id FK
        date booking_date
        time booking_time
        string token_number
        decimal locked_price
        enum status
    }
```

---

## 📱 App Screens

### Customer Screens
| Screen | Purpose |
|--------|---------|
| Home | Dashboard with quick actions |
| Browse Providers | Search & filter providers |
| Provider Details | View services, select date/slot |
| My Bookings | View all bookings, cancel option |

### Provider Screens
| Screen | Purpose |
|--------|---------|
| Dashboard | Stats overview |
| Services | Add/View/Delete services |
| Availability | Set weekly schedule |
| Profile | Update business info |

### Admin Screens
| Screen | Purpose |
|--------|---------|
| Dashboard | Stats & quick actions |
| Pending Providers | Approve/Reject providers |
| Manage Users | Block/Unblock users |
| Reports | Revenue & analytics |
| Audit Logs | Login history |

---

## 🔗 API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /auth/register | User registration |
| POST | /auth/login | User login |
| POST | /auth/verify-email | OTP verification |
| POST | /auth/forgot-password | Reset password |

### Customer
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /customer/providers | List approved providers |
| GET | /customer/providers/:id | Provider details |
| GET | /customer/providers/:id/services | Provider's services |
| GET | /customer/providers/:id/slots | Available time slots |
| GET | /customer/categories | List categories |

### Booking
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /bookings | Create booking |
| GET | /bookings/my | Customer's bookings |
| PUT | /bookings/:id/cancel | Cancel booking |

### Provider
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /provider/profile | Get profile |
| PUT | /provider/profile | Update profile |
| POST | /provider/services | Add service |
| GET | /provider/services | List services |
| DELETE | /provider/services/:id | Delete service |
| POST | /provider/availability | Set availability |
| GET | /provider/availability | Get schedule |

### Admin
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /admin/providers/pending | Pending providers |
| PUT | /admin/providers/:id/approve | Approve provider |
| PUT | /admin/providers/:id/reject | Reject provider |
| GET | /admin/users | All users |
| PUT | /admin/users/:id/block | Block user |
| PUT | /admin/users/:id/unblock | Unblock user |
| GET | /admin/reports | Analytics |
| GET | /admin/logs | Login logs |

---

## ✅ Completed Phases

| Phase | Features | Status |
|-------|----------|--------|
| **Phase 1** | Authentication, Registration, Email OTP, JWT | ✅ Complete |
| **Phase 2** | Provider Portal, Services, Availability | ✅ Complete |
| **Phase 3** | Customer Booking, Browse, Token Generation | ✅ Complete |
| **Phase 4** | Wallet & Payments | ⏳ Pending |
| **Phase 5** | Admin Dashboard, Reports, Audit Logs | ✅ Complete |
| **Phase 6** | Security & Polish | ⏳ Pending |

---

## 🚀 Deployment

### Backend (cPanel)
- **API URL:** `https://api.booknex.vayunexsolution.com`
- **Deployment:** Git Version Control

### Mobile App
- **APK Size:** 49.9 MB
- **Platform:** Android

---

## 📊 Project Stats

| Metric | Count |
|--------|-------|
| Flutter Screens | 15+ |
| API Endpoints | 25+ |
| Database Tables | 7 |
| Service Files | 5 |
| Total Code Files | 50+ |

---

**Document Generated:** February 2026
**Project:** BookNex Appointment System
**Developer:** Vayunex Solution
