import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assets/data/chinese-unit1.json 与 docs/data 同源（逐字节一致）', () {
    final asset = File('assets/data/chinese-unit1.json').readAsStringSync();
    final doc = File('../../docs/data/chinese-unit1.json').readAsStringSync();
    expect(asset, doc);
  });
}
