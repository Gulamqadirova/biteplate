import 'errors.dart';
import 'orders.dart';
import 'observers.dart';

abstract class KitchenCommand {
  String get type;
  String get description;

  void execute();
  void undo();
}

class PrepareOrderCommand implements KitchenCommand {
  final Order order;
  final OrderSubject subject;
  OrderStatus? _previous;

  PrepareOrderCommand(this.order, this.subject);

  @override
  String get type => 'prepare';
  @override
  String get description => 'Prepare ${order.code} · Table ${order.tableNumber}';

  @override
  void execute() {
    _previous = order.status;
    order.transitionTo(OrderStatus.preparing);
    subject.notify(OrderEvent('kitchen', '${order.code} is now being prepared'));
  }

  @override
  void undo() {
    if (_previous != null) {
      order.forceStatus(_previous!);
      subject.notify(OrderEvent('kitchen', 'Undo: ${order.code} returned to queue'));
    }
  }
}

class CancelOrderCommand implements KitchenCommand {
  final Order order;
  final OrderSubject subject;
  OrderStatus? _previous;

  CancelOrderCommand(this.order, this.subject);

  @override
  String get type => 'cancel';
  @override
  String get description => 'Cancel ${order.code} · Table ${order.tableNumber}';

  @override
  void execute() {
    _previous = order.status;
    order.transitionTo(OrderStatus.cancelled);
    subject.notify(OrderEvent('kitchen', '${order.code} was cancelled'));
  }

  @override
  void undo() {
    if (_previous != null) {
      order.forceStatus(_previous!);
      subject.notify(OrderEvent('kitchen', 'Undo: ${order.code} reinstated'));
    }
  }
}

class ExpediteOrderCommand implements KitchenCommand {
  final Order order;
  final OrderSubject subject;
  OrderStatus? _previous;

  ExpediteOrderCommand(this.order, this.subject);

  @override
  String get type => 'expedite';
  @override
  String get description => 'Expedite ${order.code} · Table ${order.tableNumber}';

  @override
  void execute() {
    _previous = order.status;
    order.forceStatus(OrderStatus.ready);
    subject.notify(OrderEvent('kitchen', '${order.code} expedited — ready to serve'));
  }

  @override
  void undo() {
    if (_previous != null) {
      order.forceStatus(_previous!);
      subject.notify(OrderEvent('kitchen', 'Undo: ${order.code} expedite reverted'));
    }
  }
}

class KitchenQueue {
  final List<KitchenCommand> _pending = [];
  final List<KitchenCommand> _history = [];

  void enqueue(KitchenCommand command) => _pending.add(command);

  List<KitchenCommand> get pending => List.unmodifiable(_pending);
  List<KitchenCommand> get history => List.unmodifiable(_history);

  KitchenCommand processNext() {
    if (_pending.isEmpty) {
      throw DomainException('The kitchen queue is empty.');
    }
    final command = _pending.removeAt(0);
    command.execute();
    _history.add(command);
    return command;
  }

  KitchenCommand undoLast() {
    if (_history.isEmpty) {
      throw DomainException('There is no kitchen action to undo.');
    }
    final command = _history.removeLast();
    command.undo();
    _pending.insert(0, command);
    return command;
  }
}
