import 'package:flutter/material.dart';

import '../app_state.dart';
import 'theme.dart';
import 'widgets.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.s;
    return ListenableBuilder(
      listenable: app.favorites,
      builder: (context, _) {
        final rows = app.favorites.codes.where((c) => app.byCode(c) != null).toList();
        return Scaffold(
          appBar: AppBar(title: Text(s.tabFavorites)),
          body: rows.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(s.noFavorites, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.7)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  children: [
                    for (final code in app.favorites.codes)
                      if (app.byCode(code) case final row?) Padding(padding: const EdgeInsets.only(bottom: 10), child: RowTile(row)),
                  ],
                ),
        );
      },
    );
  }
}
