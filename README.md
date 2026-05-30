# BitePlate — Smart Restaurant Management System

A prototype Smart Restaurant Management System (SRMS) for the BitePlate restaurant
chain, built for **Unit 27: Advanced Programming** (Pearson BTEC Level 5 HN).

It is a full-stack application:

| Layer | Technology | Responsibility |
| --- | --- | --- |
| **Backend** | Pure Dart (`dart:io` HTTP server) | All domain logic and the ten design patterns |
| **Frontend** | Flutter (web) | Professional dashboard UI consuming the REST API |

The backend is deliberately framework-free: every design pattern is implemented in
plain Dart classes under `lib/domain/`, so the patterns — not a framework — are the
substance of the assessment.

---

## Why Dart + Flutter? (language & IDE justification)

**Language — Dart.** Dart is a modern, strongly-typed, fully object-oriented
language (every value is an object; it supports abstract classes, interfaces via
implicit interfaces, mixins, generics and exhaustive `switch`). That makes it an
ideal vehicle for demonstrating OOP principles and the GoF patterns cleanly, without
language ceremony. Using **one** language for both the API server (`dart:io`) and the
client (Flutter) keeps the domain model, validation rules and data contracts
consistent end-to-end and avoids serialisation drift between a separate backend stack
and the UI.

**IDE — Android Studio / IntelliJ (with the Dart & Flutter plugins).** It provides
first-class Dart analysis, refactoring, run configurations and an integrated debugger
for both the server entry point and the Flutter app. VS Code with the Flutter
extension is equally supported.

---

## Architecture

```
lib/
├── domain/                     # Pure Dart — no Flutter imports. The assessed core.
│   ├── errors.dart             # DomainException (validation / rule violations)
│   ├── menu.dart               # Factory Method · Composite · Decorator
│   ├── staff.dart              # Inheritance + role-based permissions
│   ├── tables.dart             # State pattern (table lifecycle)
│   ├── orders.dart             # Order aggregate + guarded status transitions
│   ├── pricing.dart            # Strategy pattern (pricing engine)
│   ├── billing.dart            # Facade pattern (tax / tip / split)
│   ├── kitchen.dart            # Command pattern (+ undo)
│   ├── observers.dart          # Observer pattern (notifications)
│   ├── history.dart            # Singleton + Iterator (audit log)
│   └── restaurant_service.dart # Orchestration — where the patterns cooperate
├── server/
│   └── api_server.dart         # HTTP/JSON adapter, routing, CORS, error mapping
├── screens/ · widgets/ · theme/ · services/   # Flutter UI
bin/
└── server.dart                 # Backend entry point
```

The HTTP layer is a thin adapter; it never contains business rules. A
`DomainException` thrown anywhere in the domain is mapped to an HTTP 400 with a safe
message, so internal failures never leak to the client.

## Design patterns implemented

| Pattern | Category | Location |
| --- | --- | --- |
| Factory Method | Creational | `menu.dart` — `MenuItemFactory` and subclasses |
| Singleton | Creational | `history.dart` — `OrderHistoryLog` |
| Composite | Structural | `menu.dart` — `ComboMeal` over `MenuComponent` |
| Decorator | Structural | `menu.dart` — `ExtraTopping`, `SpecialPreparation`, `AllergenFlag` |
| Facade | Structural | `billing.dart` — `BillingFacade` |
| Command | Behavioural | `kitchen.dart` — `KitchenCommand` + `KitchenQueue` (undo) |
| Observer | Behavioural | `observers.dart` — `OrderSubject` + observers |
| Strategy | Behavioural | `pricing.dart` — `PricingStrategy` + concretes |
| State | Behavioural | `tables.dart` — `TableState` lifecycle |
| Iterator | Behavioural | `history.dart` — uniform traversal of the audit log |

The three Merit patterns (**Command**, **Singleton**, **Strategy**) cooperate in one
flow: a waiter **places an order** → `Decorator` builds the customised line items,
the order is appended to the **Singleton** audit log, and a `PrepareOrderCommand`
(**Command**) is queued; at checkout the **Strategy** pricing engine, wrapped by the
billing **Facade**, produces the discounted bill.

---

## Running the application

> Requires the Flutter SDK (Dart 3.x). Verified with Flutter 3.41 / Dart 3.11.

### 1. Start the backend API

```bash
dart run bin/server.dart        # serves http://localhost:8080/api
# optional: dart run bin/server.dart 9090   to use a different port
```

### 2. Run the Flutter web client (in a second terminal)

```bash
flutter pub get
flutter run -d chrome           # launches the dashboard in Chrome
```

The client polls the API every 5 seconds and reflects live state. If the backend is
not running, the UI loads but shows empty data and a connection message.

### Quick API smoke test (no UI)

```bash
curl http://localhost:8080/api/menu
curl -X POST http://localhost:8080/api/tables/1/seat
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{"tableNumber":1,"staffId":"WTR01","items":[{"menuIndex":3,"quantity":1}]}'
curl -X POST http://localhost:8080/api/kitchen/process
```

## Secure coding practices

- **Input validation** — every request field is parsed and range-checked
  (`restaurant_service.dart`, `_asInt` / `_asString`); malformed bodies and unknown
  IDs raise `DomainException`.
- **Graceful error handling** — the API never crashes on bad input; domain errors
  become 400s, unexpected errors become a generic 500 (internals are logged, not
  returned).
- **No hard-coded sensitive values** — tax rate, discounts and seed data are named
  constants/factories; there are no secrets, credentials or magic literals at call
  sites.
- **Least privilege** — actions are gated by role permissions (e.g. a Chef cannot
  take orders), enforced centrally via `Staff.require(...)`.

## Tests

```bash
flutter test        # domain unit tests (patterns, validation, billing maths)
```

See `EVALUATION.md` for the Task 3c technical evaluation (pattern fit, Singleton
trade-offs, and how the design would change at 50-restaurant scale).
