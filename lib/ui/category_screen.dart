import 'package:flutter/material.dart';

import '../ads/ad_slot.dart';
import '../app_state.dart';
import 'widgets.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final rows = app.inCategory(category);
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        itemCount: rows.length + 1,
        itemBuilder: (context, i) => i == rows.length
            ? const AdSlot(AdPlacement.resultsBanner)
            : Padding(padding: const EdgeInsets.only(bottom: 10), child: RowTile(rows[i])),
      ),
    );
  }
}
