/// 学段与年级。学段覆盖范围见 0007；本文件只定义字段，不定义覆盖范围。

/// 学段。
enum Stage {
  primary('primary'),
  junior('junior'),
  senior('senior');

  const Stage(this.wireName);

  final String wireName;

  static Stage fromWire(String value) {
    for (final stage in Stage.values) {
      if (stage.wireName == value) return stage;
    }
    throw ArgumentError.value(value, 'value', 'unknown stage');
  }
}

/// 册次。1 为上册，2 为下册。
enum Volume {
  upper(1),
  lower(2);

  const Volume(this.number);

  final int number;

  static Volume fromNumber(int value) {
    for (final volume in Volume.values) {
      if (volume.number == value) return volume;
    }
    throw ArgumentError.value(value, 'value', 'volume must be 1 or 2');
  }
}

/// 年级，取值 1–12。小学 1–6，初中 7–9，高中 10–12。
class Grade {
  const Grade._(this.value);

  final int value;

  /// 创建年级。超出 1–12 抛出 [ArgumentError]。
  factory Grade(int value) {
    if (value < 1 || value > 12) {
      throw ArgumentError.value(value, 'value', 'grade must be between 1 and 12');
    }
    return Grade._(value);
  }

  /// 由年级推导学段。
  Stage get stage {
    if (value <= 6) return Stage.primary;
    if (value <= 9) return Stage.junior;
    return Stage.senior;
  }

  @override
  bool operator ==(Object other) => other is Grade && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Grade($value)';
}
