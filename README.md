# Lakshya Smartguard systems

Lakshya Smartguard systems is a comprehensive agriculture drone service platform designed to modernize farming practices through precision technology. The application facilitates the seamless booking and execution of drone-based services such as pesticide spraying and crop monitoring, connecting farmers with certified pilots and regional retailers.

## Project Overview

Lakshya Smartguard Systems is a comprehensive agriculture drone service platform designed to modernize farming operations through precision agriculture.

The platform enables farmers and retailers to seamlessly book drone-based agricultural services such as pesticide spraying and crop monitoring. It manages the complete service lifecycle, including user onboarding, farm registration, booking creation, pilot assignment, drone allocation, payment processing, notifications, and analytics.

The application follows a modular MVVM architecture built with Flutter and Firebase, supported by a Node.js backend for workflow automation and real-time push notifications.

### Target Users
*   **Farmers**: Primary consumers who register their farms and book drone services.
*   **Retailers**: Regional partners who manage multiple farmers and facilitate service bookings.
*   **Pilots (Internal & External)**: Certified drone operators who execute the requested services.
*   **Operations**: Staff responsible for scheduling, resource allocation, and job monitoring.
*   **Admins**: Platform administrators who manage users, approvals, and system-wide analytics.

---

## Tech Stack

### Frontend
*   **Flutter**: Framework for building cross-platform applications.
*   **Dart**: Programming language used for development.

### Backend & Infrastructure

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging (FCM)
- Node.js + Express Backend
- Firebase Admin SDK
- TypeScript

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

## Application Architecture

The project follows a clean, modular MVVM architecture combined with the Repository pattern to ensure scalability and maintainability.

## Backend Services

A dedicated Node.js backend handles server-side workflows that cannot be securely executed from the client application.

Responsibilities include:

- Sending Firebase Cloud Messaging (FCM) push notifications
- Workflow event listeners
- Coupon event processing
- User event processing
- Notification synchronization
- Firestore event handling
- Secure server-side operations


### Data Flow
1.  **UI (Presentation)**: Users interact with widgets and trigger events.
2.  **ViewModel**: Handles UI logic and calls Repository methods. Listens to state changes.
3.  **Repository**: Encapsulates data fetching logic (Firestore, Auth, Storage).
4.  **Firebase**: Provides the data persistence and backend services.
5.  **Riverpod Providers**: Act as the "glue," managing the lifecycle of ViewModels and Repositories.

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
│   └── widgets/      # Shared UI components (Buttons, TextFields).
├── features/     # Domain-specific modules (Feature-based).
│   ├── auth/         # Login, Registration (Farmer/Retailer/Pilot).
│   ├── farm/         # Farm creation and management.
│   ├── booking/      # Service booking and tracking.
│   ├── pilot_jobs/   # Mission execution and job details.
│   ├── admin/        # Platform management and analytics.
│   └── retailer/     # Retailer-specific farmer management.
├── shared/       # Reusable components across multiple features.
│   ├── models/       # Common data structures (User, Activity).
│   ├── repositories/ # Shared data access logic.
│   └── enums/        # Global enumerations (UserRole, BookingStatus).
└── main.dart     # Application entry point.
```

---

## Feature Modules

### Authentication
- Multi-role authentication
- Role-based redirection
- Approval workflow
- Session persistence

### Farmer Module
- Farm registration
- Farm boundary mapping
- Service booking
- Booking tracking
- Booking history

### Retailer Module
- Farmer management
- Service booking
- Coupon application
- Notification center

### Operations Module
- Pilot assignment
- Drone assignment
- Booking scheduling
- Workflow management

### Pilot Module
- Job assignments
- Navigation
- Mission completion
- Proof uploads
- Notifications

### Admin Module
- Employee management
- Retailer approval
- External pilot approval
- Analytics dashboard
- Reports
- Coupon management
- Notification management

---

## Coupon Management

The platform includes a centralized coupon management system that allows administrators to create and manage promotional offers for retailers.

### Features

- Create and manage coupons
- Edit existing coupons
- Activate or deactivate coupons
- Configure coupon validity period
- Assign coupons to specific retailers or make them globally available
- Support percentage and fixed amount discounts
- Validate coupons during booking
- Automatically calculate applicable discounts
- Track coupon usage and remaining redemption limits
- Maintain coupon history for reporting and analytics

---

## Notification System

The application provides a real-time notification system for all user roles using Firebase Cloud Messaging (FCM) and an in-app notification center.

### Features

- Push notifications using Firebase Cloud Messaging
- In-app notification center
- Real-time notification updates
- Notification badge count
- Read/Unread notification tracking
- Notification history
- Role-based notification delivery

### Supported Roles

- Admin
- Operations
- Retailer
- Farmer
- Pilot

---

## User Roles

| Role | Responsibility | Key Actions |
| :--- | :--- | :--- |
| **Admin** | System Governance | Approve Users, Manage Employees, View Analytics |
| **Operations** | Resource Management | Assign Pilots/Drones, Monitor Active Missions |
| **Farmer** | Service Consumer | Create Farms, Book Services, Confirm Completion |
| **Retailer** | Regional Facilitator | Manage Farmers, Book Services on behalf of Farmers |
| **Pilot** | Service Executor | Accept Jobs, Navigate, Complete Missions |
| **External Pilot** | Freelance Operator | Register, Await Approval, Execute Jobs |

---

## Approval Workflow

To ensure service quality and security, several roles require manual administrator approval:

1.  **Pending**: User has registered but cannot access the application.
2.  **Approved**: Admin has verified documents; user gains full access.
3.  **Rejected**: Registration denied; user is informed of the reason.
4.  **Suspended**: Account access revoked due to policy violations.

---

## Database Structure (Firestore)

### Users Collection
Stores profile data, roles, account status, and pilot-specific statistics.
*   **Relationship**: One User has Many Farms; One User has Many Bookings.

### Bookings Collection
Stores job metadata, assigned resources, status history, and mission results.
*   **Key Fields**: `farmerUid`, `pilotId`, `droneId`, `status`, `bookingDate`.

### Farms Collection
Stores farm-specific data including boundaries and location.
*   **Relationship**: Linked to `Users` via `ownerUid`.

### Activity Logs
Centralized tracking of system-wide events for the Admin dashboard.

### Notifications Collection

Stores all in-app notifications.

Key Fields:

- recipientId
- recipientRole
- title
- body
- isRead
- createdAt
- notificationType
- referenceId

### Coupons Collection

Stores all coupon information.

Key Fields:

- code
- discountType
- value
- startDate
- endDate
- assignedRetailers
- applicableServices
- remainingUsage

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
*   **Approval Gate**: Crucial roles (Retailer/External Pilot) are locked until the `approvalStatus` is updated to `approved`.

---

## Known Limitations

- Real-time drone telemetry is planned for a future release.
- Integrated payment gateway (PhonePe) is under development.

## Future Enhancements

- PhonePe payment gateway
- Live drone tracking
- AI-powered crop health insights
- Offline support
- Wallet system
- Advanced analytics
- Multi-language expansion

---

## Dependencies

| Package | Purpose |
| :--- | :--- |
| `flutter_riverpod` | State Management |
| `go_router` | Navigation |
| `cloud_firestore` | Database |
| `flutter_map` | OpenStreetMap Integration |
| `geolocator` | GPS Services |
| `maps_launcher` | External Navigation |
| `excel` | Report Generation |
| firebase_messaging | Push Notifications |
| flutter_local_notifications | Local Notifications |
| firebase_storage | File Uploads |
| firebase_auth | Authentication |
| image_picker | Image Upload |
| flutter_dotenv | Environment Variables |

---

## Contributing
1.  **Branching**: `feature/feature-name` or `fix/issue-name`.
2.  **Commits**: Use conventional commits (e.g., `feat:`, `fix:`, `chore:`).
3.  **Pull Requests**: Must pass `flutter analyze` and require one peer review.

---

## License
Copyright © 2024 Lakshya Smartguard systems. All rights reserved.
Proprietary software. Unauthorized copying, distribution, or use is strictly prohibited.
