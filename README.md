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
- **Payment Gateway**: Integrated digital payment solution.

### Maps & Navigation
*   **Flutter Map & OpenStreetMap (OSM)**: Base layer for farm mapping and GPS coordinates.
*   **Geolocator**: Real-time position tracking for pilots.

---

## System Architecture

The application follows a modular **MVVM (Model-View-ViewModel)** architecture on the frontend, communicating with a distributed backend layer.

### Enterprise Payment & Sync Flow
1.  **Initiation**: Flutter App requests a payment session from the Node.js backend.
2.  **Orchestration**: Backend generates a unique transaction ID, creates a pending record in Firestore, and signs the request.
3.  **Execution**: User completes the transaction via a secure WebView.
4.  **Reconciliation**: The gateway sends an asynchronous callback webhook to the Node.js backend.
5.  **Atomic Sync**: The backend executes a Firestore `db.runTransaction` to update both the `payments` and `bookings` collections simultaneously, ensuring the "Source of Truth" is always consistent.
6.  **Real-time UI**: Flutter listeners (Riverpod) detect the Firestore change and automatically transition the user to the Success/Failure screens.

---

## Key Modules & Features

### 💳 Payment Gateway & Financials
Integrated secure Payment Gateway with support for real-time reconciliation. Includes:
*   **Checksum Verification**: Prevents request tampering.
*   **Atomic Transactions**: Zero inconsistent data states between payments and bookings.
*   **Idempotency Guards**: Prevents duplicate processing of webhooks.
*   **Development Mock Mode**: Full end-to-end testing without live gateway keys.

### 💰 Wallet & Incentives
A comprehensive earnings ledger for Pilots and Copilots:
*   **Dynamic Rates**: Acreage-based incentive calculation via global system settings.
*   **Transaction History**: Detailed audit trail of earnings and "Incentive Paid" events.
*   **Admin Controls**: One-click balance settlement and manual payment recording.

### 🔔 Real-time & Custom Notification System
A comprehensive notification routing and delivery system that handles both automated workflow alerts and custom operations broadcasts:
*   **Targeted Role-based Routing**: Users (Farmers, Retailers, Pilots, Operations, Admins) receive only notifications matching their specific roles and IDs to keep their feed relevant and private.
*   **Operations Broadcast Center**: Operations Team users and Admins have access to a secure, premium Notification Composer dashboard (`OpsNotificationsScreen`) where they can draft custom notifications (100-character title limit, 500-character description limit) and view a live push notification layout preview before confirming transmission.
*   **Flexible Recipients**: Broadcasts can target entire user groups (All Farmers, All Internal Pilots, All External Pilots, All Retailers, All Operations, Everyone) or specific searched and role-filtered individual users.
*   **Dual Storage and FCM Pipeline**: The backend service (`notification.routes.ts` & `notification.service.ts`) logs a master delivery campaign record to the `custom_notifications` collection while batch-creating individual user notifications in the `notifications` collection (reusing the existing FCM multicast/push pipeline and preserving separate read states).
*   **History Logs**: Features a detailed history viewer (`GET /api/notifications/history`) with keyword filters, date range chips (Today, This Week, This Month), sent/failed delivery statistics, and color-coded status tags.
*   **Security & Authorization**: All operations broadcast routes (`/api/notifications/send` and `/api/notifications/history`) verify the authenticated user via Firebase ID tokens (`auth.middleware.ts`), lookup the user document in Firestore (by UID field or Document ID), and enforce role-based authorization to only permit access for `operations` and `admin` roles.

### 🚁 Pilot Operations & Live Tracking
Specialized interface for mission execution and tracking:
*   **Integrated OSM Navigation**: Interactive route overlays using Flutter Map, OSM tiles, and OSRM server routing.
*   **Real-time GPS Tracking**: When a pilot initiates a trip (En Route or En Route to Office), the app requests location permissions (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) and initializes the `LocationTrackingService` to listen for coordinate updates.
*   **Distance Filtering**: Locations are updated and pushed to Firestore dynamically whenever the pilot moves significantly (by 25 meters, distance filter range 20-30m) to save device battery and minimize network requests.
*   **Firestore Telemetry**: Updates are written to the specific booking's `liveLocation` map field (`latitude`, `longitude`, `accuracy`, `speed`, `heading`, `updatedAt`).
*   **Live Tracking Map**: Farmers and Operations staff view real-time pilot coordinates via the `LiveTrackingMap` widget. It automatically calculates the route/ETA via OSRM service and renders a rotating pilot marker aligned with the pilot's GPS heading.
*   **Field Business Logic**: Includes cash collection validation, office deposit reporting, and retailer coupon verification.

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
    │   ├── phonepe/     # Payment Gateway Logic & Checksum Utilities
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
    # Configure .env with Firebase and Payment Gateway keys
    npm run dev
    ```
2.  **Mobile Setup**:
    ```bash
    flutter pub get
    # For Android testing with local backend
    flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api --dart-define=BOOKING_RATE_PER_ACRE=800
    ```

Production builds require an HTTPS `API_BASE_URL`. See
[`PRODUCTION_RELEASE.md`](PRODUCTION_RELEASE.md) for signing, Firebase rules,
store disclosures, and release validation.

---

## Security & Reliability
*   **Data Integrity**: Read-Before-Write Firestore transactions ensure payments are never lost.
*   **API Security**: Rate limiting and UUID-based request tracing on all endpoints.
*   **Gateway Security**: Industry-standard SHA-256 HMAC checksums for all external communications.

---

## License
Copyright © 2024 Lakshya Smartguard systems. All rights reserved.
Proprietary software. Unauthorized copying, distribution, or use is strictly prohibited.
