import 'package:material_ui/material_ui.dart';

import 'ui/unit_list_page.dart';

void main() {
  runApp(const LelexueEnglishApp());
}

class LelexueEnglishApp extends StatelessWidget {
  const LelexueEnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '乐乐学 英语',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: const UnitListPage(),
    );
  }
}
