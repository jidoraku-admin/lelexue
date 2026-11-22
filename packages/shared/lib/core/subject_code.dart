/// 学科编码。用于标识学科数据归属，不保存学科内容。
enum SubjectCode {
  english('english'),
  math('math'),
  chinese('chinese'),
  physics('physics'),
  chemistry('chemistry');

  const SubjectCode(this.wireName);

  /// 跨服务传输时使用的字符串。
  final String wireName;

  /// 从传输字符串解析。未知编码抛出 [ArgumentError]。
  static SubjectCode fromWire(String value) {
    for (final code in SubjectCode.values) {
      if (code.wireName == value) return code;
    }
    throw ArgumentError.value(value, 'value', 'unknown subject code');
  }
}
