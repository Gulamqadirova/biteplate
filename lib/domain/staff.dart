/// Staff domain — INHERITANCE + ABSTRACTION + role-based access control.
///
/// [Staff] is an abstract base that captures identity and the permission-check
/// contract. Each concrete role (Manager, Waiter, Chef, Cashier) declares the
/// set of [Permission]s it grants. Permission checks go through [require],
/// which throws a [DomainException] the API maps to HTTP 403 — adding a new
/// role never touches existing call sites.
library;

import 'errors.dart';

/// Granular capabilities, decoupled from roles so new roles compose existing
/// permissions (see Task 4 — Scenario E).
enum Permission {
  takeOrder,
  modifyKitchenQueue,
  processBilling,
  closeBill,
  manageStaff,
  viewReports,
}

extension PermissionLabel on Permission {
  String get label => switch (this) {
        Permission.takeOrder => 'Take Orders',
        Permission.modifyKitchenQueue => 'Manage Kitchen',
        Permission.processBilling => 'Process Billing',
        Permission.closeBill => 'Close Bills',
        Permission.manageStaff => 'Manage Staff',
        Permission.viewReports => 'View Reports',
      };
}

abstract class Staff {
  final String id;
  final String name;

  Staff(this.id, this.name) {
    if (id.trim().isEmpty || name.trim().isEmpty) {
      throw DomainException('Staff id and name are required.');
    }
  }

  String get role;

  /// The permissions this role grants — the only thing subclasses must define.
  Set<Permission> get permissions;

  bool can(Permission permission) => permissions.contains(permission);

  /// Guard used by services before privileged actions.
  void require(Permission permission) {
    if (!can(permission)) {
      throw DomainException('$role "$name" is not permitted to '
          '${permission.label.toLowerCase()}.');
    }
  }

  /// Two-letter monogram for avatars.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class Manager extends Staff {
  Manager(super.id, super.name);
  @override
  String get role => 'Manager';
  @override
  Set<Permission> get permissions => Permission.values.toSet(); // everything
}

class Waiter extends Staff {
  Waiter(super.id, super.name);
  @override
  String get role => 'Waiter';
  @override
  Set<Permission> get permissions => {Permission.takeOrder, Permission.closeBill};
}

class Chef extends Staff {
  Chef(super.id, super.name);
  @override
  String get role => 'Chef';
  @override
  Set<Permission> get permissions => {Permission.modifyKitchenQueue};
}

class Cashier extends Staff {
  Cashier(super.id, super.name);
  @override
  String get role => 'Cashier';
  @override
  Set<Permission> get permissions =>
      {Permission.processBilling, Permission.closeBill};
}
