import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../amal/data/amal_repository.dart';
// ─── STATE ───────────────────────────────────────────────────────────────────
class HeatmapState {
  final Map<String, double> data;
  const HeatmapState({required this.data});
}
// ─── NOTIFIER ────────────────────────────────────────────────────────────────
class HeatmapNotifier extends AsyncNotifier<HeatmapState> {
  late final AmalRepository _repo;
  @override
  Future<HeatmapState> build() async {
    _repo = AmalRepository();
    return _load();
  }
  Future<HeatmapState> _load() async {
    final to = DateTime.now();
    final from = to.subtract(const Duration(days: 365));
    final data = await _repo.getHeatmapData(from: from, to: to);
    return HeatmapState(data: data);
  }
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}
// ─── PROVIDER ────────────────────────────────────────────────────────────────
final heatmapProvider = AsyncNotifierProvider<HeatmapNotifier, HeatmapState>(
  HeatmapNotifier.new,
);
