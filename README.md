# Fuodz Driver (Glover Delivery Boy)

A professional, feature-rich Flutter application designed for delivery partners and taxi drivers within the **Fuodz** multi-service ecosystem. It enables drivers to receive, manage, and complete orders for general deliveries (food, groceries, packages) as well as ride-hailing/taxi services.

---

## 🚀 Project Overview

The **Fuodz Driver** app acts as the critical bridge between customers, vendors, and delivery/taxi services. By utilizing real-time communications, background location tracking, and an MVVM architecture, it provides drivers with a seamless workflow from onboarding and vehicle verification to route navigation and payout settlement.

---

## ✨ Key Features

### 📦 Delivery Service
*   **Order Lifecycle Management**: Real-time order dispatch, request acceptance/rejection, store pickup, and delivery tracking.
*   **Proof of Delivery**: Verification mechanisms such as QR code scanning (`qr_code_scanner_plus`) and in-app signature capture (`hand_signature`) upon order completion.
*   **Package Stop Verification**: Multi-stop tracking and verification for package delivery tasks.

### 🚖 Taxi & Ride-Hailing Service
*   **Taxi Booking Allocation**: Drivers can receive, accept, or reject taxi ride requests nearby.
*   **Ride Tracking**: Live coordinates updating for both driver and passenger to coordinate pickups and drop-offs.
*   **Flexible Vehicle Registration**: Add vehicle makes, models, plate numbers, and upload verification documents. Drivers can also switch between registered vehicles.

### 📍 Location & Routing
*   **Background Location Synchronization**: Periodically syncs driver coordinates (`/driver/location/sync`) with the backend, even when the app is in the background, using `geolocator`, `flutter_background`, and a location watcher service.
*   **Interactive Maps**: Powered by `google_maps_flutter` with dynamic route navigation using polylines and external maps launcher integrations (`map_launcher`).

### 💬 Communication & Notifications
*   **Real-time Messaging**: Multi-user chat support using Firebase Firestore, allowing direct text communication between drivers, customers, and vendors.
*   **High-Priority Push Dispatch**: Uses WebSockets (via Pusher/Socket.io client) and Firebase Cloud Messaging (FCM) along with overlay windows (`flutter_overlay_window`) to ensure drivers never miss incoming requests.

### 💳 Financial Management & Wallet
*   **Digital Wallet**: Track wallet balances, view transactional history, and perform wallet-to-wallet transfers.
*   **Payout Accounts**: Manage payout banking details and initiate withdrawal requests.
*   **Earnings Reports**: Downloadable earnings and payout summary reports in PDF format.

---

## 🛠️ Architecture & Tech Stack

This project is built using modern Flutter development best practices:

*   **State Management & Architecture**: [Stacked Architecture](https://pub.dev/packages/stacked) (MVVM pattern), ensuring clean separation of Concerns:
    *   **Views**: UI code containing widgets and styles (utilizing `VelocityX` for responsive UI utility design).
    *   **ViewModels**: Logic controllers that handle states and coordinate with services.
    *   **Services**: Reusable modules managing business logic (Authentication, HTTP networking, Location Tracking, WebSockets, Firebase, etc.).
*   **Networking**: REST API communication managed by `Dio` with request/response caching (`dio_http_cache_lts`) and structured logging (`pretty_dio_logger`).
*   **Real-Time Data**: WebSockets with Laravel Echo integrations for listening to order dispatch channels.
*   **Localization**: Multi-language support driven by `localize_and_translate`.

---

## ⚙️ Configuration & Getting Started

### Prerequisites

*   Flutter SDK: `^3.7.2`
*   CocoaPods (for iOS builds)
*   Android SDK & Build Tools (for Android builds)

### Configuration

The app defaults to the production endpoint configured in `lib/constants/api.dart`:
```dart
static const defaultBaseUrl = "https://glover.edentech.online/api";
```

### Build Environment & Build Time Variables

You can inject custom API endpoints during compilation using Flutter's `--dart-define` option. The injected path must include the `/api` suffix.

#### Run in Debug Mode with Custom API:
```sh
flutter run --dart-define=api=https://your-domain.com/api
```

#### Build Android APK:
```sh
flutter build apk --dart-define=api=https://your-domain.com/api
```

#### Build iOS App:
```sh
flutter build ios --dart-define=api=https://your-domain.com/api
```

---

## 📚 Flutter Resources

For developers new to Flutter:
*   [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
*   [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)
*   [Online Documentation](https://flutter.dev/docs) - tutorials, samples, mobile development guides, and full API reference.
