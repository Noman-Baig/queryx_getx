import 'package:get/get.dart';
import 'package:queryx/queryx.dart';

import 'snapshots.dart';

/// Bridges a queryx [InfiniteQuery] into a reactive GetX controller.
class InfiniteQueryxController<T, P> extends GetxController {
  InfiniteQueryxController(this._query);

  final InfiniteQuery<T, P> _query;
  late final Rx<InfiniteQueryxSnapshot<T, P>> snapshot;

  InfiniteQueryxSnapshot<T, P> get value => snapshot.value;

  @override
  void onInit() {
    super.onInit();
    snapshot = InfiniteQueryxSnapshot.fromInfiniteQuery(_query).obs;
    _query.addListener(_onChange);
    if (_query.pages.isEmpty) {
      // ignore: discarded_futures
      _query.fetchNextPage();
    }
  }

  void _onChange() =>
      snapshot.value = InfiniteQueryxSnapshot.fromInfiniteQuery(_query);

  Future<void> fetchNextPage() => _query.fetchNextPage();
  Future<void> fetchPreviousPage() => _query.fetchPreviousPage();
  @override
  Future<void> refresh() => _query.refresh();
  void reset() => _query.reset();

  @override
  void onClose() {
    _query.removeListener(_onChange);
    _query.dispose();
    super.onClose();
  }
}
