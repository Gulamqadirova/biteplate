/// Notifications — OBSERVER pattern.
///
/// [OrderSubject] maintains a list of [OrderObserver]s and broadcasts an
/// [OrderEvent] whenever order/kitchen/table state changes. Concrete observers
/// (waiter, manager dashboard, kitchen display, allergy alert) react
/// independently. New recipients are added by registering another observer —
/// existing code is never touched (open/closed principle, Task 4 — Scenario B).
library;

class OrderEvent {
  /// Channel tag the UI colour-codes: order | kitchen | billing | table | alert
  final String type;
  final String message;
  final DateTime timestamp;

  OrderEvent(this.type, this.message) : timestamp = DateTime.now();
}

abstract class OrderObserver {
  void onEvent(OrderEvent event);
}

/// SUBJECT — anything that emits events to subscribers.
class OrderSubject {
  final List<OrderObserver> _observers = [];

  void subscribe(OrderObserver observer) => _observers.add(observer);
  void unsubscribe(OrderObserver observer) => _observers.remove(observer);

  void notify(OrderEvent event) {
    for (final o in List.of(_observers)) {
      o.onEvent(event);
    }
  }
}

/// Central in-memory feed that several observers write into, exposed to the UI
/// as the notifications list.
class NotificationFeed {
  final List<OrderEvent> _events = [];
  void add(OrderEvent event) => _events.insert(0, event);
  List<OrderEvent> get latest => List.unmodifiable(_events);
}

/// Base observer that only reacts to its own set of channels, so a shared feed
/// never receives the same event twice.
abstract class _ChannelObserver implements OrderObserver {
  final NotificationFeed feed;
  final Set<String> channels;
  _ChannelObserver(this.feed, this.channels);

  @override
  void onEvent(OrderEvent event) {
    if (channels.contains(event.type)) feed.add(event);
  }
}

/// Front-of-house waiter — sees order and table activity.
class WaiterNotifier extends _ChannelObserver {
  WaiterNotifier(NotificationFeed feed) : super(feed, {'order', 'table'});
}

/// Management view — sees billing activity.
class ManagerDashboard extends _ChannelObserver {
  ManagerDashboard(NotificationFeed feed) : super(feed, {'billing'});
}

/// Kitchen screen — sees kitchen activity.
class KitchenDisplay extends _ChannelObserver {
  KitchenDisplay(NotificationFeed feed) : super(feed, {'kitchen'});
}

/// Demonstrates that a brand-new recipient can be added with zero edits to the
/// subject or other observers — it raises an explicit allergy alert.
class AllergyAlertObserver extends _ChannelObserver {
  AllergyAlertObserver(NotificationFeed feed) : super(feed, {'alert'});
}
