# Lakshya Smartguard systems

Lakshya Smartguard systems is a comprehensive agriculture drone service platform designed to modernize farming practices through precision technology. The application facilitates the seamless booking and execution of drone-based services such as pesticide spraying and crop monitoring, connecting farmers with certified pilots and regional retailers.

## Project Overview

Lakshya Smartguard Systems is a comprehensive agriculture drone service platform designed to modernize farming operations through precision agriculture.

The platform enables farmers and retailers to seamlessly book drone-based agricultural services such as pesticide spraying and crop monitoring. It manages the complete service lifecycle, including user onboarding, farm registration, booking creation, pilot assignment, mission progress tracking, payment confirmation, notifications, and analytics.

The application follows a modular MVVM architecture built with Flutter and Firebase, supported by a Node.js backend for workflow automation and real-time alerts.

### Target Users
*   **Farmers**: Primary consumers who register their farms and book drone services.
*   **Retailers**: Regional partners who manage multiple farmers and facilitate service bookings.
*   **Pilots (Internal & External)**: Certified drone operators who execute the requested services.
*   **Operations**: Staff responsible for scheduling, resource allocation, and job monitoring.
*   **Admins**: Platform administrators who manage users, approvals, incentives, and system-wide analytics.

---

## Tech Stack

### Frontend
*   **Flutter**: Framework for building cross-platform applications.
*   **Dart**: Programming language used for development.

### Backend & Infrastructure
- **Firebase Authentication**: Secure user management (Email/Password).
- **Cloud Firestore**: NoSQL document database for real-time data storage.
- **Firebase Storage**: Hosting for user documents and profile photographs.
- **Firebase Cloud Messaging (FCM)**: Push notifications for job updates and approvals.
- **Node.js + Express Backend**: Dedicated service for workflow automation and secure operations.

### Architecture & State Management
*   **MVVM (Model-View-ViewModel)**: Separation of UI logic from business logic.
*   **Repository Pattern**: Abstracted data layer for Firebase interactions.
*   **Riverpod**: Declarative state management and dependency injection.
*   **GoRouter**: Declarative routing with support for deep links and role-based redirects.

### Maps & Navigation
*   **Flutter Map**: Open-source map widget for Flutter.
*   **OpenStreetMap (OSM)**: Base layer for farm location and mapping.
*   **Geolocator**: Real-time GPS location services.
*   **Maps Launcher**: External navigation trigger for third-party map applications.

---

## Project Structure

```text
lib/
├── app/          # App-wide configuration and global entry points.
├── core/         # Cross-cutting concerns and infrastructure.
│   ├── constants/    # Fixed values like sizes, spacing, and keys.
│   ├── theme/        # App styling (colors, typography, decorations).
│   ├── routes/       # GoRouter configuration and role-based redirection.
│   ├── services/     # Utility services (File upload, Logging).
│   ├── localization/ # Multi-language support (English/Telugu).
│   ├── notifications/# Real-time notification management.
│   └── widgets/      # Shared UI components (Buttons, TextFields).
├── features/     # Domain-specific modules (Feature-based).
│   ├── auth/         # Login, Registration (Farmer/Retailer/Pilot).
│   ├── farm/         # Farm creation and management.
│   ├── booking/      # Service booking and tracking.
│   ├── pilot_jobs/   # Mission execution and job details.
│   ├── admin/        # Platform management and analytics.
│   ├── retailer/     # Retailer-specific farmer management.
│   └── wallet/       # Earnings tracking and salary management.
├── shared/       # Reusable components across multiple features.
│   ├── models/       # Common data structures (User, Activity).
│   ├── repositories/ # Shared data access logic.
│   └── enums/        # Global enumerations (UserRole, BookingStatus).
└── main.dart     # Application entry point.
```

---

## Key Modules & Features

### Authentication Module
Handles multi-role authentication. Includes role-based redirection, registration approval workflows for retailers and external pilots, and session persistence.

### Booking & Farm Module
Enables farmers and retailers to register farms with precise GPS coordinates using OSM. Supports a full booking lifecycle from request to approval, assignment, and completion.

### Wallet Module (Earnings Ledger)
A comprehensive system for Pilots and Copilots to track service-based incentives. It calculates earnings dynamically based on acreage and provides a detailed transaction history of earnings and salary payments.

### Notification System
A real-time in-app notification center that alerts users about critical events such as booking approvals, pilot assignments, mission progress (En Route, Arrived, Started, Completed), and payment confirmations. Supports push notifications via FCM.

### Pilot Module
Specialized interface for operators to accept assignments, navigate to farm locations, record mission telemetry, upload proof of service, and verify retailer coupons.

### Admin Module
Provides platform-wide oversight, including employee management, retailer/pilot approvals, incentive configuration, coupon management, and business analytics.

---

## User Roles

| Role | Responsibility | Key Actions |
| :--- | :--- | :--- |
| **Admin** | System Governance | Approve Users, Manage Employees, Configure Rates, View Analytics |
| **Operations** | Resource Management | Approve Bookings, Assign Pilots, Monitor Active Missions |
| **Farmer** | Service Consumer | Create Farms, Book Services, Confirm Completion |
| **Retailer** | Regional Facilitator | Manage Farmers, Book Services with Coupons |
| **Pilot** | Service Executor | Accepting Jobs, Navigation, Mission Completion, Cash Collection |
| **External Pilot** | Freelance Operator | Register, Await Approval, Execute Jobs |

---

## Database Structure (Firestore)

### Users Collection
Stores profile data, roles, account status, wallet balances, and performance statistics.

### Bookings Collection
Stores job metadata, assigned resources, status history, payment status, and mission results.

### Wallet Transactions
Ledger entries for pilot/copilot incentives and salary payments.

### Salary Payments
Records of historical salary payments made to employees outside the application.

### System Settings
Global configuration for incentive rates (e.g., `pilotRatePerAcre`, `copilotRatePerAcre`).

### Activity Logs
Centralized tracking of system-wide events for the Admin dashboard.

---

## Setup Guide

### Prerequisites
*   Flutter SDK (v3.12.0 or higher)
*   Android Studio / VS Code
*   Firebase Project access

### Installation
1.  Clone the repository.
2.  Run `flutter pub get` to install dependencies.
3.  Configure Firebase:
    *   Place `google-services.json` in `android/app/`.
    *   Place `GoogleService-Info.plist` in `ios/Runner/`.
4.  Run `flutter run` to launch the application.

---

## Security
*   **Authentication**: Managed by Firebase Auth with role-based validation.
*   **Access Control**: Firestore Rules restrict data access based on user UID and role.
*   **Approval Gate**: Retailer and External Pilot roles are locked until Admin verification.

---

## Known Limitations
- Real-time drone telemetry is planned for a future release.
- Integrated payment gateway (PhonePe) is under development.

## Future Enhancements
*   Advanced Analytics for Farmers (Yield Prediction).
*   Offline Map Support for remote areas.
*   AI-powered crop health insights.
*   Full digital payment gateway integration.

---

## License
Copyright © 2024 Lakshya Smartguard systems. All rights reserved.
Proprietary software. Unauthorized copying, distribution, or use is strictly prohibited.
