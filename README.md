# Lakshya Smartguard systems

Lakshya Smartguard systems is a comprehensive agriculture drone service platform designed to modernize farming practices through precision technology. The application facilitates the seamless booking and execution of drone-based services such as pesticide spraying and crop monitoring, connecting farmers with certified pilots and regional retailers.

## Project Overview

Lakshya Smartguard Systems is an enterprise-grade platform designed to modernize farming operations. It manages the complete service lifecycle, including user onboarding, farm registration, booking creation, pilot assignment, mission progress tracking, automated financial reconciliation, and real-time alerts.

The system utilizes a hybrid cloud architecture, combining the real-time capabilities of **Firebase** with a dedicated **Node.js/TypeScript backend** for secure payment orchestration and workflow automation.

### Target Users
*   **Farmers**: Register farms and book precision drone services.
*   **Retailers**: Facilitate bookings for farmers using promotional coupons.
*   **Pilots (Internal & External)**: Execute missions and manage field operations.
*   **Operations**: Manage resource allocation (Pilots/Drones) and monitor active missions.
*   **Admins**: System governance, financial confirmation, and business analytics.

---

## Tech Stack

### Frontend & Mobile
*   **Flutter**: Cross-platform framework for iOS and Android.
*   **Riverpod**: Declarative state management and dependency injection.
*   **GoRouter**: Modular routing with role-based access control.
*   **WebView Flutter**: Secure integration for payment gateway interfaces.

### Backend & Infrastructure
- **Firebase Authentication**: Multi-role secure user management.
- **Cloud Firestore**: NoSQL real-time database with atomic transaction support.
- **Firebase Storage**: Secure hosting for pilot certificates and service proofs.
- **Node.js + Express (TypeScript)**: Enterprise backend for payment processing and sensitive business logic.
- **PhonePe Payment Gateway**: Integrated digital payment solution.

### Maps & Navigation
*   **Flutter Map & OpenStreetMap (OSM)**: Base layer for farm mapping and GPS coordinates.
*   **Geolocator**: Real-time position tracking for pilots.

---

## System Architecture

The application follows a modular **MVVM (Model-View-ViewModel)** architecture on the frontend, communicating with a distributed backend layer.

### Enterprise Payment & Sync Flow
1.  **Initiation**: Flutter App requests a payment session from the Node.js backend.
2.  **Orchestration**: Backend generates a unique `merchantTransactionId`, creates a pending record in Firestore, and signs the request with a **SHA-256 HMAC signature (X-VERIFY)** for PhonePe.
3.  **Execution**: User completes the transaction via a secure WebView using UPI, Cards, or NetBanking.
4.  **Reconciliation**: PhonePe sends an asynchronous **Webhook** to the Node.js backend.
5.  **Atomic Sync**: The backend executes a Firestore `db.runTransaction` to update both the `payments` and `bookings` collections simultaneously, ensuring the "Source of Truth" is always consistent.
6.  **Real-time UI**: Flutter listeners (Riverpod) detect the Firestore change and automatically transition the user to the Success/Failure screens.

---

## Key Modules & Features

### 💳 Payment Gateway & Financials
Integrated **PhonePe PG** with support for real-time reconciliation. Includes:
*   **HMAC Signature Security**: Prevents request tampering.
*   **Atomic Transactions**: Zero inconsistent data states between payments and bookings.
*   **Idempotency Guards**: Prevents duplicate processing of webhooks.
*   **Development Mock Mode**: Full end-to-end testing without live gateway keys.

### 💰 Wallet & Incentives
A comprehensive earnings ledger for Pilots and Copilots:
*   **Dynamic Rates**: Acreage-based incentive calculation via global system settings.
*   **Transaction History**: Detailed audit trail of earnings and "Incentive Paid" events.
*   **Admin Controls**: One-click balance settlement and manual payment recording.

### 🔔 Real-time Notifications
Centralized notification hub delivering alerts for:
*   Booking approvals and Pilot assignments.
*   Mission updates (En Route, Arrived, Started, Completed).
*   Payment and Deposit confirmations.

### 🚁 Pilot Operations
Specialized interface for mission execution, including:
*   Integrated OSM Navigation.
*   Retailer Coupon Verification logic.
*   Cash collection and office deposit reporting.

---

## Project Structure

```text
├── lib/               # Flutter Application
│   ├── app/           # App-wide config & entry points
│   ├── core/          # Infrastructure (Routes, Theme, Services)
│   │   └── notifications/ # Notification orchestration
│   ├── features/      # Domain-specific modules
│   │   ├── auth/      # Login & Approval Workflows
│   │   ├── admin/     # Governance & Analytics
│   │   ├── booking/   # Lifecycle Engine
│   │   ├── pilot/     # Job execution & Dashboard
│   │   ├── retailer/  # Farmer & Coupon management
│   │   └── wallet/    # Earnings & Incentives
│   └── shared/        # Common Models, Enums, and Repositories
└── backend/           # Node.js Enterprise Service
    ├── src/
    │   ├── controllers/ # HTTP Request Handling
    │   ├── phonepe/     # Gateway Logic & Checksum Utilities
    │   ├── firebase/    # Admin SDK & Atomic Transactions
    │   └── middleware/  # Security & Log Tracing
```

---

## Setup Guide

### Prerequisites
*   Flutter SDK (v3.12.0+)
*   Node.js (v18.0+) & npm
*   Firebase Project Credentials

### Installation
1.  **Backend Setup**:
    ```bash
    cd backend
    npm install
    # Configure .env with Firebase and PhonePe keys
    npm run dev
    ```
2.  **Mobile Setup**:
    ```bash
    flutter pub get
    # For Android testing with local backend
    flutter run --dart-define=PAYMENT_BASE_URL=http://10.0.2.2:3000/api/payment
    ```

---

## Security & Reliability
*   **Data Integrity**: Read-Before-Write Firestore transactions ensure payments are never lost.
*   **API Security**: Rate limiting and UUID-based request tracing on all endpoints.
*   **Gateway Security**: Industry-standard SHA-256 HMAC checksums for all external communications.

---

## License
Copyright © 2024 Lakshya Smartguard systems. All rights reserved.
Proprietary software. Unauthorized copying, distribution, or use is strictly prohibited.
