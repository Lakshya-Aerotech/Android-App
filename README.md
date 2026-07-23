# Lakshya Smartguard systems

Lakshya Smartguard systems is a comprehensive agriculture drone service platform designed to modernize farming practices through precision technology. The application facilitates the seamless booking and execution of drone-based services such as pesticide spraying and crop monitoring, connecting farmers with certified pilots and regional retailers.

## Project Overview

The application serves as a centralized ecosystem for agricultural drone services. It bridges the gap between technology providers and end-users (farmers) by managing the entire service lifecycle—from registration and farm mapping to service booking, pilot assignment, and job execution.

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
*   **Firebase Authentication**: Secure user management (Email/Password).
*   **Cloud Firestore**: NoSQL document database for real-time data storage.
*   **Firebase Storage**: Hosting for user documents and profile photographs.
*   **Firebase Cloud Messaging**: Push notifications for job updates and approvals.

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
│   ├── retailer/     # Retailer-specific farmer management.
│   └── wallet/       # Earnings tracking and salary management.
├── shared/       # Reusable components across multiple features.
│   ├── models/       # Common data structures (User, Activity).
│   ├── repositories/ # Shared data access logic.
│   └── enums/        # Global enumerations (UserRole, BookingStatus).
└── main.dart     # Application entry point.
```

---

## Feature Modules

### Authentication Module
Handles multi-role authentication using Email and Password. It manages session persistence, password resets, and role identification during the login process.

### Admin Module
Provides platform-wide oversight. Features include employee management (Operations/Pilots), External Pilot approvals, Retailer management, and performance analytics.

### Booking Module
The core workflow engine. Allows Farmers and Retailers to schedule services, select farms, and track job progress from "Pending" to "Closed."

### Farm Module
Enables users to register farms by capturing details such as crop type, area, and precise GPS coordinates using an interactive OpenStreetMap picker.

### Pilot Jobs Module
A specialized interface for operators to accept assignments, navigate to farm locations, record mission telemetry, and upload service completion proofs.

### Wallet Module (Earnings Ledger)
A comprehensive system for Pilots and Copilots to track their service-based incentives. It calculates earnings dynamically based on acreage and provides a detailed transaction history of earnings and salary payments.

### Notification System
A real-time in-app notification center that alerts users about critical events such as booking approvals, pilot assignments, mission progress, and payment confirmations.

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
*   **Key Fields**: `farmerUid`, `pilotId`, `copilotId`, `status`, `bookingDate`, `payableAmount`, `paymentStatus`.

### Wallet Transactions
Ledger entries for pilot/copilot incentives and salary payments.

### Salary Payments
Records of historical salary payments made to employees outside the application.

### System Settings
Global configuration for incentive rates (e.g., `pilotRatePerAcre`, `copilotRatePerAcre`).

### Farms Collection
Stores farm-specific data including boundaries and location.
*   **Relationship**: Linked to `Users` via `ownerUid`.

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
*   **Approval Gate**: Crucial roles (Retailer/External Pilot) are locked until the `approvalStatus` is updated to `approved`.

---

## Known Limitations
*   In-app real-time drone tracking (Planned for v2.0).
*   Integrated payment gateway (Currently handled externally).

## Future Enhancements
*   Advanced Analytics for Farmers (Yield Prediction).
*   Offline Map Support for remote areas.
*   In-app digital payment gateway integration.

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

---

## Contributing
1.  **Branching**: `feature/feature-name` or `fix/issue-name`.
2.  **Commits**: Use conventional commits (e.g., `feat:`, `fix:`, `chore:`).
3.  **Pull Requests**: Must pass `flutter analyze` and require one peer review.

---

## License
Copyright © 2024 Lakshya Smartguard systems. All rights reserved.
Proprietary software. Unauthorized copying, distribution, or use is strictly prohibited.
