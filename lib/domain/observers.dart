class OrderEvent {
  final String type;
  final String message;
  final DateTime timestamp;

  OrderEvent(this.type, this.message) : timestamp = DateTime.now();
}

abstract class OrderObserver {
  void onEvent(OrderEvent event);
}

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

class NotificationFeed {
  final List<OrderEvent> _events = [];
  void add(OrderEvent event) => _events.insert(0, event);
  List<OrderEvent> get latest => List.unmodifiable(_events);
}

abstract class _ChannelObserver implements OrderObserver {
  final NotificationFeed feed;
  final Set<String> channels;
  _ChannelObserver(this.feed, this.channels);

  @override
  void onEvent(OrderEvent event) {
    if (channels.contains(event.type)) feed.add(event);
  }
}

class WaiterNotifier extends _ChannelObserver {
  WaiterNotifier(NotificationFeed feed) : super(feed, {'order', 'table'});
}
class ManagerDashboard extends _ChannelObserver {
  ManagerDashboard(NotificationFeed feed) : super(feed, {'billing'});
}
class KitchenDisplay extends _ChannelObserver {
  KitchenDisplay(NotificationFeed feed) : super(feed, {'kitchen'});
}
class AllergyAlertObserver extends _ChannelObserver {
  AllergyAlertObserver(NotificationFeed feed) : super(feed, {'alert'});
}
