/// 学生身份来源（#7 userId 对接）。
///
/// 全局 UserId 由身份服务发放（identity.md §6）。英语只读取它，不生成。
/// 身份服务尚未接入数据库，当前只有内存骨架，因此默认实现返回 null：
/// 未取得 UserId 时，待发布结果保留在本地队列，不发送。
abstract class StudentIdentity {
  /// 当前学生的全局 UserId；未登录或身份服务未就绪时为 null。
  String? get userId;
}

/// 默认实现：没有身份服务，始终为 null。
class NoStudentIdentity implements StudentIdentity {
  const NoStudentIdentity();

  @override
  String? get userId => null;
}
