# Internal Technical Documentation: NusantaraGPS

**Version:** 2.0.0
**Date:** December 29, 2025
**Type:** Engineering Handover & Onboarding

---

## 1. Application Overview

**NusantaraGPS** is a vehicle monitoring and tracking application designed for Android. It allows users to monitor fleet movements in real-time, view historical trip data, and manage vehicle configurations.

The system relies on a dual-API strategy:

1. **Traccar API:** Handles high-volume telemetry data (positions, raw routes, geofences).
2. **Internal Backend:** Handles business logic, user authentication, vehicle management, and aggregated reporting.

**Target Users:** Fleet managers, logistics coordinators, and individual vehicle owners.

---

## 2. Technology Stack & Dependencies

### Core Framework

* **Flutter & Dart:** Primary development framework.
* **Architecture:** MVVM (Model-View-ViewModel) with Clean Architecture principles.

### Key Libraries

| Category | Library | Purpose |
| --- | --- | --- |
| **State Management** | `provider` | Manages UI state and business logic injection. |
| **Routing** | `go_router` | Handles deep linking, navigation stacks, and route guards (Auth checks). |
| **Networking** | `dio` | HTTP client with Interceptors for token injection and error handling. |
| **Dependency Injection** | `get_it` | Service locator for decoupling ViewModels, Repositories, and Datasources. |
| **Maps** | `Maps_flutter` | Rendering the map interface. |
| **Geolocation** | `geolocator` | Accessing the device's current GPS position. |
| **Local Storage** | `shared_preferences` | (Abstracted via `IKeyValueStorage`) Storing tokens and user session data. |

---

## 3. Application Architecture

The application follows a strict **MVVM** pattern with a **Domain-Driven** separation of concerns.

### Data Flow Pipeline

1. **Screen (UI):** Listens to the ViewModel. No business logic allowed here.
2. **ViewModel:** Holds state, calls Repositories, handles UI-specific logic (e.g., polling timers).
3. **Repository:** The decision maker. It fetches data from Remote DataSources, maps **DTOs** to **Domain Entities**, and returns clean data or Failures to the ViewModel.
4. **Remote DataSource:** Handles the raw HTTP implementation (Endpoints, JSON parsing).
5. **API:** External endpoints.

### The DTO vs. Entity Strategy

A core architectural rule in this project is the strict separation between Data Transfer Objects (DTOs) and Domain Entities.

* **DTO (`*.dto.dart`):**
* Represent the exact JSON structure returned by the API.
* Fields are often `Nullable` to prevent parsing crashes if the API changes.
* Example: `VehicleDto` (contains raw JSON fields).


* **Entity (`*.dart`):**
* Represents the data actually used by the UI and ViewModels.
* Fields are `Non-Nullable` where possible, providing default values (e.g., empty strings or 0.0) to ensure UI stability.
* **Benefit:** API changes only require updates to the DTO and the Mapper method (`toEntity()`), leaving the rest of the app untouched.



---

## 4. Project Folder Structure

```text
lib/
├── core/
│   ├── config/             # AppConfig, Environment variables
│   ├── di/                 # Dependency Injection setup (locator)
│   ├── service/            # Low-level services (Dio, Storage)
│   └── utils/              # Extensions, Formatters
├── data/
│   ├── datasource/         # Raw API calls (Traccar, Internal, LocationIQ)
│   ├── dto/                # JSON parsing models
│   ├── models/             # Domain Entities (used by UI/VM)
│   └── repositories/       # Implementation of Domain Interfaces
├── domain/
│   ├── entities/           # Enums, Core Entities
│   ├── interfaces/         # Abstract contracts for Repositories
│   └── manager/            # Global managers (SessionManager)
├── presentation/
│   ├── screens/            # UI code grouped by feature
│   │   ├── 1_auth/
│   │   ├── 3_maps/
│   │   └── ...
│   └── widgets/            # Reusable UI components
└── main.dart               # Entry point

```

---

## 5. State Management Strategy

* **Provider** is used to inject ViewModels into Screens.
* **Loading States:** ViewModels typically expose a `ViewState` enum (Initial, Loading, Success, Error).
* **Error Handling:** Errors are caught in the Repository, wrapped in a `Result` or `Failure` object, and passed to the ViewModel to decide how to show them (Snackbar vs Error Screen).

---

## 6. Authentication & Security

### Login Flow (`AuthRepositoryImpl`)

1. User submits credentials via `IAuthRemoteDataSource`.
2. On success, the app receives a payload containing **two distinct tokens**:
* `token`: For Internal API (Vehicle management, Reports).
* `traccarToken`: For Traccar API (Tracking, Geofencing).


3. Tokens and user info are stored securely via `IKeyValueStorage`.

### Session Management

* **Route Guard:** `AppRoute` checks `SessionManager.authState`. If `unauthenticated`, the user is redirected to `/login`.
* **Auto Logout:** Implemented via Dio Interceptors (logic resides in `DioService`, though not fully shown in provided code, the repository handles 401 errors).
* **Data Persistence:** Credentials and tokens are persisted to handle app restarts without requiring re-login.

---

## 7. Realtime Tracking & Polling Mechanism

* **Mechanism:** Periodic Polling (HTTP GET).
* **Implementation:**
* The `FollowDeviceViewModel` (inferred) triggers a timer.
* Calls `TrackingRepositoryImpl.getPosition()`.
* Updates the `PositionModel` which refreshes markers on the map.


* **Concurrency Control:** `CancelToken` is supported in some repository methods (e.g., `fetchTripReportsByDate`) to cancel stale requests if the user changes filters or screens rapidly.

> **Note:** Polling was chosen over WebSockets likely due to API limitations or implementation simplicity on the backend side.

---

## 8. Feature-by-Feature Breakdown

### A. Maps & Tracking (`TrackingRepositoryImpl`)

* **Source:** Traccar API (`i_traccar_remote_data_source.dart`).
* **Reverse Geocoding:** Uses **LocationIQ** via `ILocationIqRemoteDataSource`.
* **Logic:** Fetches devices and positions. Delays are artificially injected (see Section 11) in the repository layer.

### B. Vehicle Management (`VehicleRepositoryImpl`)

* **Source:** Internal API (`i_vehicle_remote_data_source.dart`).
* **Capabilities:**
* `getVehicles`: Supports pagination and search.
* `getDetailVehicle`: Fetches specific metadata.



### C. Trip Reports (`VehicleRepositoryImpl`)

* **Dual Source Logic:**
* **Route Path (Points):** Fetched from Traccar (`fetchRouteReportsByDate`). Used for drawing polyline on map.
* **Summary (Stop/Start):** Fetched from Internal API (`fetchTripReportsByDate`). Used for the list of trips.


* **Date Handling:** Inputs are String-based in DataSource but converted to `DateTime` in Repository.

### D. Favorite Locations (`MapsRepositoryImpl`)

* **Source:** Internal API.
* **Functionality:** CRUD operations for user-defined points of interest.
* **Data Flow:** `FavoriteLocationDTO` -> `FavoriteLocationModel`.

---

## 9. API Integration Overview

| API Service | Base URL | Auth Method | Responsibility |
| --- | --- | --- | --- |
| **Internal API** | (Configured in AppConfig) | Bearer `auth.token` | Login, Vehicles, Fav Locations, Aggregated Reports |
| **Traccar API** | (Configured in AppConfig) | Bearer `auth.traccartoken` | Live Position, Raw History, Geofences |
| **LocationIQ** | `https://us1.locationiq.com/v1/` | Query Param `key` | Reverse Geocoding (Lat/Lng to Address) |

---

## 10. Error Handling Strategy

Errors are categorized in `AuthRepositoryImpl` (and applied similarly elsewhere) using a custom `Failure` class:

* **HTTP 400/401:** Mapped to `FailureType.invalidCredentials`.
* **HTTP 429:** Mapped to `FailureType.rateLimited`.
* **HTTP 500+:** Mapped to `FailureType.server`.
* **Network/Socket:** Mapped to `FailureType.network`.
* **Parsing Error:** Mapped to `FailureType.malformedResponse`.

>**All The Error Mapping is Already has Extension**  
> please check on file `core/utils/error_extention.dart`.

These failures are returned to the ViewModel, which determines the UI response (e.g., "Check Internet Connection").

---

## 11. Known Issues & Technical Debt

The following items are present in the current codebase and should be addressed in future sprints:

1. **Artificial Delays (CRITICAL):**
* `TrackingRepositoryImpl.getPosition()` contains `await Future.delayed(const Duration(seconds: 1));`.
* `VehicleRemoteDataSourceImpl.getDetailVehicle()` contains `await Future.delayed(const Duration(seconds: 1));`.
* `MapsRepositoryImpl.getInitialLocation()` contains `await Future.delayed(const Duration(milliseconds: 500));`.
* **Impact:** This artificially slows down the app and makes the UI feel sluggish. These should be removed unless they serve a specific throttling purpose (which should be done via debouncing, not `delayed`).


2. **Hardcoded Coordinates:**
* `MapsRepositoryImpl.getInitialLocation()` returns hardcoded coordinates (`-7.905...`).
* **Impact:** The map will always center on this location initially, regardless of the user's actual location or vehicle location.


3. **Mixing Logic in Repository:**
* `MapsRepositoryImpl` handles `FavoriteLocations`. Ideally, this should be in a dedicated `FavoriteLocationRepository` to adhere to Single Responsibility Principle.


4. **Sensitive Keys:**
* `AppConfig.locationIqApiKey` is referenced. Ensure this key is not committed in plaintext in the repository (use `.env` or build flags).



---

## 12. Recommendations for Future Development

1. **Refactor Polling:** Move from simple polling to **WebSockets** (Traccar supports this) for true real-time updates and reduced battery/data usage.
2. **Remove Delays:** Immediately remove the `Future.delayed` calls found in the DataSources and Repositories.
3. **Centralize Coordinates:** Move the hardcoded initial coordinates to a configuration file or replace them with the user's current geolocation.
4. **Pagination UI:** Ensure the `VehicleListViewModel` handles infinite scrolling correctly, as the API supports pagination (`page` parameter).
5. **Unit Testing:** The clear separation of DTOs and Entities makes this project highly testable. Add unit tests for the `Repository` layer to verify mapping logic.