import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:amal_app/core/database/database_helper.dart';
import 'package:amal_app/features/amal/data/amal_repository.dart';
import 'package:amal_app/features/amal/domain/amal.dart';
import 'package:amal_app/features/amal/domain/amal_record.dart';
import 'package:amal_app/features/amal/presentation/providers/amal_provider.dart';
import 'package:amal_app/features/amal/presentation/screens/home_screen.dart';

String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

String _today() => _fmt(DateTime.now());

Amal _makeAmal({
  required String title,
  AmalType type = AmalType.checkbox,
  int? countTarget,
  int sortOrder = 0,
  String? createdAt,
}) => Amal(
  id: 0,
  title: title,
  type: type,
  countTarget: countTarget,
  sortOrder: sortOrder,
  isActive: true,
  createdAt: createdAt ?? DateTime.now().toIso8601String(),
);

// ─── MAIN ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.useInMemoryForTesting();
  });

  tearDown(() async {
    await DatabaseHelper().resetForTesting();
  });

  // ─── REPOSITORY ──────────────────────────────────────────────────────────

  group('AmalRepository —', () {
    late AmalRepository repo;
    setUp(() => repo = AmalRepository());

    test('əməl əlavə edilir və geri oxunur', () async {
      final id = await repo.insertAmal(_makeAmal(title: 'Sübh namazı'));
      expect(id, greaterThan(0));
      final list = await repo.getActiveAmals();
      expect(list.length, 1);
      expect(list.first.title, 'Sübh namazı');
    });

    test('əməl silinir', () async {
      final id = await repo.insertAmal(_makeAmal(title: 'Sil məni'));
      await repo.deleteAmal(id);
      expect(await repo.getActiveAmals(), isEmpty);
    });

    test('checkbox record yazılır', () async {
      final id = await repo.insertAmal(_makeAmal(title: 'Quran'));
      final td = _today();
      await repo.upsertRecord(
        AmalRecord(
          amalId: id,
          recordDate: td,
          isCompleted: true,
          completedAt: DateTime.now().toIso8601String(),
        ),
      );
      final rec = await repo.getRecord(id, td);
      expect(rec?.isCompleted, isTrue);
    });

    test('checkbox tamamlandıqdan sonra geri alınır', () async {
      final id = await repo.insertAmal(_makeAmal(title: 'Zikr'));
      final td = _today();
      await repo.upsertRecord(
        AmalRecord(
          amalId: id,
          recordDate: td,
          isCompleted: true,
          completedAt: td,
        ),
      );
      await repo.upsertRecord(
        AmalRecord(amalId: id, recordDate: td, isCompleted: false),
      );
      expect((await repo.getRecord(id, td))?.isCompleted, isFalse);
    });

    test('counter artırılır sonra azaldılır', () async {
      final id = await repo.insertAmal(
        _makeAmal(title: 'Təsbeh', countTarget: 33),
      );
      final td = _today();
      await repo.upsertRecord(
        AmalRecord(amalId: id, recordDate: td, countDone: 5),
      );
      await repo.upsertRecord(
        AmalRecord(amalId: id, recordDate: td, countDone: 4),
      );
      expect((await repo.getRecord(id, td))?.countDone, 4);
    });

    test('streak 60 günü keçdikdə düzgün hesablanır', () async {
      final id = await repo.insertAmal(
        Amal(
          id: 0,
          title: 'Uzun streak',
          type: AmalType.checkbox,
          sortOrder: 0,
          isActive: true,
          createdAt: DateTime.now()
              .subtract(const Duration(days: 90))
              .toIso8601String(),
        ),
      );
      for (int i = 0; i < 90; i++) {
        final date = _fmt(DateTime.now().subtract(Duration(days: i)));
        await repo.upsertRecord(
          AmalRecord(
            amalId: id,
            recordDate: date,
            isCompleted: true,
            completedAt: date,
          ),
        );
      }
      expect(await repo.calculateStreak(id), 90);
    });

    test('getRecordsForDate bütün bugünkü recordları qaytarır', () async {
      final td = _today();
      final ids = <int>[];
      for (int i = 0; i < 3; i++) {
        final id = await repo.insertAmal(
          _makeAmal(title: 'Əməl $i', sortOrder: i),
        );
        ids.add(id);
        await repo.upsertRecord(
          AmalRecord(
            amalId: id,
            recordDate: td,
            isCompleted: true,
            completedAt: td,
          ),
        );
      }
      final records = await repo.getRecordsForDate(td);
      expect(records.length, 3);
      expect(records.map((r) => r.amalId).toSet(), containsAll(ids));
    });

    test('getStreakBrokenAmals kəsilmiş əməlləri qaytarır', () async {
      final yesterday = _fmt(DateTime.now().subtract(const Duration(days: 1)));
      final dayBefore = _fmt(DateTime.now().subtract(const Duration(days: 2)));
      final ago5 = DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String();

      final idA = await repo.insertAmal(
        Amal(
          id: 0,
          title: 'Kəsilmiş',
          type: AmalType.checkbox,
          sortOrder: 0,
          isActive: true,
          createdAt: ago5,
        ),
      );
      await repo.upsertRecord(
        AmalRecord(
          amalId: idA,
          recordDate: dayBefore,
          isCompleted: true,
          completedAt: dayBefore,
        ),
      );

      final idB = await repo.insertAmal(
        Amal(
          id: 0,
          title: 'Davam edən',
          type: AmalType.checkbox,
          sortOrder: 1,
          isActive: true,
          createdAt: ago5,
        ),
      );
      await repo.upsertRecord(
        AmalRecord(
          amalId: idB,
          recordDate: dayBefore,
          isCompleted: true,
          completedAt: dayBefore,
        ),
      );
      await repo.upsertRecord(
        AmalRecord(
          amalId: idB,
          recordDate: yesterday,
          isCompleted: true,
          completedAt: yesterday,
        ),
      );

      final broken = await repo.getStreakBrokenAmals();
      expect(broken.length, 1);
      expect(broken.first.id, idA);
    });

    test('heatmap: arxivlənmiş əməl keçmiş nisbəti dəyişdirmir', () async {
      final now = DateTime.now();
      final created = now.subtract(const Duration(days: 10)).toIso8601String();
      final nineDaysAgo = _fmt(now.subtract(const Duration(days: 9)));

      final id1 = await repo.insertAmal(
        Amal(
          id: 0,
          title: 'A1',
          type: AmalType.checkbox,
          sortOrder: 0,
          isActive: true,
          createdAt: created,
        ),
      );
      final id2 = await repo.insertAmal(
        Amal(
          id: 0,
          title: 'A2',
          type: AmalType.checkbox,
          sortOrder: 1,
          isActive: true,
          createdAt: created,
        ),
      );

      for (final id in [id1, id2]) {
        await repo.upsertRecord(
          AmalRecord(
            amalId: id,
            recordDate: nineDaysAgo,
            isCompleted: true,
            completedAt: nineDaysAgo,
          ),
        );
      }

      final before = await repo.getHeatmapData(
        from: now.subtract(const Duration(days: 15)),
        to: now,
      );
      expect(before[nineDaysAgo], closeTo(1.0, 0.01));

      await repo.updateAmal(
        Amal(
          id: id2,
          title: 'A2',
          type: AmalType.checkbox,
          sortOrder: 1,
          isActive: false,
          createdAt: created,
        ),
      );

      final after = await repo.getHeatmapData(
        from: now.subtract(const Duration(days: 15)),
        to: now,
      );
      expect(after[nineDaysAgo], closeTo(1.0, 0.01));
    });

    test(
      'import: ID konflikti olduqda recordlar düzgün əmələ bağlanır',
      () async {
        final existingId = await repo.insertAmal(_makeAmal(title: 'Mövcud'));

        final importedAmal = Amal(
          id: existingId,
          title: 'Import',
          type: AmalType.checkbox,
          sortOrder: 1,
          isActive: true,
          createdAt: DateTime.now().toIso8601String(),
        );
        final importRecord = AmalRecord(
          amalId: existingId,
          recordDate: '2025-01-01',
          isCompleted: true,
          completedAt: '2025-01-01',
        );

        await repo.importData(amals: [importedAmal], records: [importRecord]);

        final all = await repo.getAllAmals();
        expect(all.length, 2);

        final newAmal = all.firstWhere((a) => a.title == 'Import');
        expect(newAmal.id, isNot(existingId));
        expect(
          (await repo.getRecord(newAmal.id, '2025-01-01'))?.isCompleted,
          isTrue,
        );
        expect(await repo.getRecord(existingId, '2025-01-01'), isNull);
      },
    );
  });

  // ─── PROVIDER ────────────────────────────────────────────────────────────

  group('AmalNotifier —', () {
    ProviderContainer makeContainer() => ProviderContainer();

    test('başlanğıcda boş state', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final s = await c.read(amalProvider.future);
      expect(s.amals, isEmpty);
      expect(s.allCompleted, isFalse);
    });

    test('addAmal state-i yenilənir', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(amalProvider.future);
      await c.read(amalProvider.notifier).addAmal(_makeAmal(title: 'Yeni'));
      final s = await c.read(amalProvider.future);
      expect(s.amals.length, 1);
      expect(s.amals.first.title, 'Yeni');
    });

    test('completeCheckbox → tamamlanmış', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(amalProvider.future);
      await c.read(amalProvider.notifier).addAmal(_makeAmal(title: 'X'));
      final id = (await c.read(amalProvider.future)).amals.first.id;
      await c.read(amalProvider.notifier).completeCheckbox(id);
      expect(
        (await c.read(amalProvider.future)).records[id]?.isCompleted,
        isTrue,
      );
    });

    test('undoCheckbox → tamamlanmamış', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(amalProvider.future);
      await c.read(amalProvider.notifier).addAmal(_makeAmal(title: 'Y'));
      final id = (await c.read(amalProvider.future)).amals.first.id;
      await c.read(amalProvider.notifier).completeCheckbox(id);
      await c.read(amalProvider.notifier).completeCheckbox(id);
      expect(
        (await c.read(amalProvider.future)).records[id]?.isCompleted,
        isFalse,
      );
    });

    test('decrementCounter azaldır', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(amalProvider.future);
      await c
          .read(amalProvider.notifier)
          .addAmal(
            _makeAmal(title: 'C', type: AmalType.counter, countTarget: 10),
          );
      final id = (await c.read(amalProvider.future)).amals.first.id;
      await c.read(amalProvider.notifier).incrementCounter(id);
      await c.read(amalProvider.notifier).incrementCounter(id);
      await c.read(amalProvider.notifier).decrementCounter(id);
      expect((await c.read(amalProvider.future)).records[id]?.countDone, 1);
    });

    test('deleteAmal siyahıdan silinir', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(amalProvider.future);
      await c.read(amalProvider.notifier).addAmal(_makeAmal(title: 'Sil'));
      final id = (await c.read(amalProvider.future)).amals.first.id;
      await c.read(amalProvider.notifier).deleteAmal(id);
      expect((await c.read(amalProvider.future)).amals, isEmpty);
    });
  });

  // ─── WIDGET ──────────────────────────────────────────────────────────────

  group('HomeScreen —', () {
    testWidgets('boş halda empty state görünür', (t) async {
      await t.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await t.pumpAndSettle();
      expect(find.textContaining('Hər gün bir addım'), findsOneWidget);
    });

    testWidgets('"Günün əməlləri" başlığı görünür', (t) async {
      await t.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await t.pumpAndSettle();
      expect(find.text('Günün əməlləri'), findsOneWidget);
    });

    testWidgets('idarəetmə ikonu mövcuddur', (t) async {
      await t.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);
    });

    testWidgets('settings ikonu birbaşa HomeScreen-dədir', (t) async {
      await t.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('irəliləyiş çubuğu görünür', (t) async {
      await t.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomeScreen())),
      );
      await t.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
