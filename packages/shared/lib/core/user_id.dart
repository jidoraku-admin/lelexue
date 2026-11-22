/// 全局用户 ID。学科数据只引用它，不保存个人资料。
class UserId {
  const UserId._(this.value);

  final String value;

  /// 创建用户 ID。空字符串抛出 [ArgumentError]。
  factory UserId(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, 'value', 'user id must not be empty');
    }
    return UserId._(value);
  }

  @override
  bool operator ==(Object other) => other is UserId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'UserId($value)';
}
