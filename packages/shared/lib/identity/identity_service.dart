/// 共享身份服务骨架（P2，内存实现，不接数据库）。
///
/// 依据 docs/architecture/shared/identity.md（v0.3）与英语 #7 的身份模型：
/// - 家长账号为主账号，默认每位家长最多 3 名学生。
/// - 班级或机构账号按席位计价，席位上限由配置给出。
/// - 学生账号从属于母账号，不能独立注册、付费或开启推送。
/// - 学生登录名为 4–16 位小写字母与数字。
/// - 权益挂在母账号上，学生继承。
library identity_service;

import '../core/core.dart';

/// 账号类型。
enum AccountKind { parent, classOrInstitution, student }

/// 账号的内部记录。
class Account {
  Account({
    required this.userId,
    required this.kind,
    this.loginName,
    this.parentId,
    this.seatLimit,
  });

  final UserId userId;
  final AccountKind kind;

  /// 仅学生账号使用的字母登录名。
  final String? loginName;

  /// 学生账号所属的母账号。
  UserId? parentId;

  /// 母账号的席位上限（班级或机构）。家长账号使用 [IdentityService.maxStudentsPerParent]。
  final int? seatLimit;
}

/// 权益状态。挂在母账号上。
class Entitlement {
  const Entitlement({required this.paid, required this.trialActive});

  final bool paid;
  final bool trialActive;

  bool get active => paid || trialActive;
}

/// 身份服务的错误。
class IdentityException implements Exception {
  IdentityException(this.message);

  final String message;

  @override
  String toString() => 'IdentityException: $message';
}

class IdentityService {
  IdentityService({this.maxStudentsPerParent = 3});

  /// 家长账号可绑定的学生上限（英语 #7 第 1 条）。
  final int maxStudentsPerParent;

  final Map<UserId, Account> _accounts = {};
  final Map<UserId, Entitlement> _entitlements = {};
  final Set<String> _loginNames = {};

  static final RegExp _loginNamePattern = RegExp(r'^[a-z0-9]{4,16}$');

  /// 登记母账号（家长、班级或机构）。
  UserId registerParent(UserId userId, {int? seatLimit}) {
    _ensureNew(userId);
    _accounts[userId] = Account(
      userId: userId,
      kind: seatLimit == null ? AccountKind.parent : AccountKind.classOrInstitution,
      seatLimit: seatLimit,
    );
    _entitlements[userId] = const Entitlement(paid: false, trialActive: false);
    return userId;
  }

  /// 由母账号创建学生账号，占用一个席位。
  UserId createStudent({
    required UserId parentId,
    required UserId studentId,
    required String loginName,
  }) {
    final parent = _requireAccount(parentId);
    if (parent.kind == AccountKind.student) {
      throw IdentityException('students cannot create students');
    }
    if (!_loginNamePattern.hasMatch(loginName)) {
      throw IdentityException('login name must be 4-16 lowercase letters or digits');
    }
    if (_loginNames.contains(loginName)) {
      throw IdentityException('login name already in use');
    }
    final limit = parent.kind == AccountKind.parent ? maxStudentsPerParent : parent.seatLimit!;
    if (seatsUsed(parentId) >= limit) {
      throw IdentityException('no seat left for this account');
    }
    _ensureNew(studentId);
    _accounts[studentId] = Account(
      userId: studentId,
      kind: AccountKind.student,
      loginName: loginName,
      parentId: parentId,
    );
    _loginNames.add(loginName);
    return studentId;
  }

  /// 解除母子关系并释放席位。学生账号保留，但不再属于该母账号。
  void unlink(UserId parentId, UserId studentId) {
    final student = _requireAccount(studentId);
    if (student.parentId != parentId) {
      throw IdentityException('student does not belong to this parent');
    }
    student.parentId = null;
  }

  /// 已占用的席位数。
  int seatsUsed(UserId parentId) =>
      _accounts.values.where((a) => a.kind == AccountKind.student && a.parentId == parentId).length;

  /// 设置母账号的权益。
  void setEntitlement(UserId parentId, Entitlement entitlement) {
    final parent = _requireAccount(parentId);
    if (parent.kind == AccountKind.student) {
      throw IdentityException('entitlement belongs to a parent account');
    }
    _entitlements[parentId] = entitlement;
  }

  /// 查询权益。学生返回其母账号的权益。
  Entitlement getEntitlement(UserId userId) {
    final account = _requireAccount(userId);
    final owner = account.kind == AccountKind.student ? account.parentId : userId;
    if (owner == null) {
      return const Entitlement(paid: false, trialActive: false);
    }
    return _entitlements[owner] ?? const Entitlement(paid: false, trialActive: false);
  }

  /// 学生账号不能独立付费。调用此方法会抛出异常。
  void purchase(UserId userId) {
    final account = _requireAccount(userId);
    if (account.kind == AccountKind.student) {
      throw IdentityException('students cannot purchase independently');
    }
    _requireAccount(userId);
  }

  Account _requireAccount(UserId userId) {
    final account = _accounts[userId];
    if (account == null) {
      throw IdentityException('unknown account: ${userId.value}');
    }
    return account;
  }

  void _ensureNew(UserId userId) {
    if (_accounts.containsKey(userId)) {
      throw IdentityException('account already exists: ${userId.value}');
    }
  }
}
