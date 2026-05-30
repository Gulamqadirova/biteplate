# Technical Evaluation (Task 3c)

## Were the three patterns the best fit? What alternatives were considered?

**Command (Kitchen Queue).** Reifying each kitchen action as an object is the right
fit because the queue needs *undo* and a replayable history — exactly what Command
gives by pairing `execute()` with `undo()` and storing executed commands on a stack.
The alternative, a plain `Queue<Order>` with status flags, cannot undo without
scattering bespoke rollback code across the service. Command keeps each action's
forward and reverse logic together. The trade-off is more classes (one per action)
and the need to capture previous state inside each command.

**Singleton (Order History Log).** The audit log must be a single, globally reachable
record shared by billing, the dashboard and reporting; Singleton guarantees one
instance. The considered alternative was passing an injected log everywhere
(dependency injection), which is more testable but adds wiring noise for what is
genuinely a single shared resource. I mitigated the main downside (see below) with a
`resetForTesting()` seam.

**Strategy (Pricing Engine).** Pricing rules change at runtime (Happy Hour, Loyalty,
Group), so swapping an algorithm behind a stable interface is textbook Strategy. The
alternative — `if/switch` on a pricing mode inside `Bill` — would force edits to the
billing class for every new rule, violating open/closed. Strategy's cost is one small
class per rule, which is cheap and self-documenting.

## Trade-offs of the Singleton: testability and thread safety

The Singleton couples callers to a global, which normally hurts **testability**
because tests share mutable state and leak into one another. I addressed this with a
static `resetForTesting()` method so each test starts clean, but a constructor-
injected log would be cleaner still. On **thread safety**: Dart is single-threaded
per isolate, so the eager-initialised instance is safe here without locks. That
safety is an artefact of the runtime, not the design — ported to a multi-threaded
language the same Singleton would need synchronised access or a lock-free append, and
concurrent writes to the backing `List` would otherwise corrupt it.

## Scaling to 50 restaurants on one central database

The biggest change is the Singleton: one in-memory log per process cannot back 50
branches. `OrderHistoryLog` would become a thin repository over a shared database,
keeping its `append`/iterator interface but persisting rows — the Iterator already
hides storage, so reporting code is unaffected. In-memory `RestaurantService` state
(tables, orders) would move to per-branch persistence keyed by a `branchId`, and the
Factory Method layer would graduate to an **Abstract Factory** producing each branch's
menu family. Strategy, Command, Decorator and Observer are stateless or per-request
and scale unchanged. The Observer feed would shift from an in-process list to a
message bus so notifications fan out across branches.
