import 'errors.dart';

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
  Set<Permission> get permissions;
  bool can(Permission permission) => permissions.contains(permission);
  void require(Permission permission) {
    if (!can(permission)) {
      throw DomainException('$role "$name" is not permitted to '
          '${permission.label.toLowerCase()}.');
    }
  }

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
