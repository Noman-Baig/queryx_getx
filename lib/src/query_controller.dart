import 'dart:async';

import 'package:get/get.dart';
import 'package:queryx/queryx.dart';

import 'snapshots.dart';

/// Bridges a queryx [Query] into a reactive GetX controller. Wiring happens
/// in [onInit] (not the constructor) — GetX's own lifecycle hook, called
/// synchronously by `Get.put()`/`Get.find()` — so this behaves correctly
/// whether the controller is created directly or via dependency injection.
///
/// ```dart
/// final controller = Get.put(QueryxController<List<User>>(
///   queryxClient.query(QueryKey(['users']), api.getUsers),
/// ));
///
/// Obx(() => controller.snapshot.value.when(
///   loading: () => const CircularProgressIndicator(),
///   error: (e) => Text(e.message),
///   data: (users) => UserList(users),
/// ));
/// ```
///
/// In practice, prefer the [useQuery] helper over constructing this
/// directly — it also handles registering/finding the controller by tag so
/// multiple widgets asking for the same [QueryKey] share one controller.
class QueryxController<T> extends GetxController {
  QueryxController(this._query);

  final Query<T> _query;
  late final Rx<QueryxSnapshot<T>> snapshot;

  /// Shortcut for `snapshot.value` — handy inside `Obx(() => ...)`.
  QueryxSnapshot<T> get value => snapshot.value;

  @override
  void onInit() {
    super.onInit();
    snapshot = QueryxSnapshot.fromQuery(_query).obs;
    _query.addListener(_onChange);
    // Initial fetch (or an immediate resolve if the shared cache already
    // has fresh data — ensureFetched() checks that). Errors are already
    // captured on the query's own state via the listener above.
    unawaited(_query.ensureFetched().then((_) {}, onError: (_) {}));
  }

  void _onChange() => snapshot.value = QueryxSnapshot.fromQuery(_query);

  Future<T> refetch() => _query.refetch();
  @override
  Future<T> refresh() => _query.refresh();
  void invalidate() => _query.invalidate();
  void reset() => _query.reset();
  void cancel() => _query.cancel();

  @override
  void onClose() {
    _query.removeListener(_onChange);
    // Releasing the observer here — not deleting the cache — is what keeps
    // cross-widget cache sharing working: if another controller elsewhere
    // still has this query open, its data survives; otherwise the core
    // engine's own cacheTime GC takes over from here.
    _query.dispose();
    super.onClose();
  }
}
