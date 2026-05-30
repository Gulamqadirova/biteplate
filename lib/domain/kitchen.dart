/// Kitchen action queue — COMMAND pattern.
///
/// Each kitchen action (prepare, cancel, expedite) is reified as a [KitchenCommand]
/// with `execute()` and `undo()`. [KitchenQueue] is the invoker: it holds a
/// FIFO of pending commands and a history stack so the last executed action can
/// be undone. The [Order] acts as the receiver. The waiter (caller) never knows
/// which concrete command it triggered.
library;

import 'errors.dart';
import 'orders.dart';
import 'observers.dart';

abstract class KitchenCommand {
  /// Tag the UI colour-codes: prepare | cancel | expedite.
  String get type;
  String get description;

  void execute();
  void undo();
}

/// Advances an order into preparation; undo rolls it back to confirmed.
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

/// Cancels an order before service; undo restores the prior status.
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

/// Pushes an order straight to ready (priority); undo rolls it back.
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

/// INVOKER — owns the pending FIFO and an executed-history stack for undo.
class KitchenQueue {
  final List<KitchenCommand> _pending = [];
  final List<KitchenCommand> _history = [];

  void enqueue(KitchenCommand command) => _pending.add(command);

  List<KitchenCommand> get pending => List.unmodifiable(_pending);
  List<KitchenCommand> get history => List.unmodifiable(_history);

  /// Executes the next pending command and records it for undo.
  KitchenCommand processNext() {
    if (_pending.isEmpty) {
      throw DomainException('The kitchen queue is empty.');
    }
    final command = _pending.removeAt(0);
    command.execute();
    _history.add(command);
    return command;
  }

  /// Undoes the most recently executed command and returns it to the queue.
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
