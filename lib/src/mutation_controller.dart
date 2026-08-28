import 'package:get/get.dart';
import 'package:queryx/queryx.dart';

import 'snapshots.dart';

/// Bridges a queryx [Mutation] into a reactive GetX controller. Unlike
/// queries, mutations don't auto-run — call [mutate]/[mutateAsync]
/// explicitly (a button press, form submit, etc.).
class MutationxController<T, V, C> extends GetxController {
  MutationxController(this._mutation);

  final Mutation<T, V, C> _mutation;
  late final Rx<MutationSnapshot<T>> snapshot;

  MutationSnapshot<T> get value => snapshot.value;

  @override
  void onInit() {
    super.onInit();
    snapshot = MutationSnapshot.fromMutation(_mutation).obs;
    _mutation.addListener(_onChange);
  }

  void _onChange() => snapshot.value = MutationSnapshot.fromMutation(_mutation);

  /// Runs the mutation and returns its result — use this when you want to
  /// `await`/`try-catch` the outcome directly.
  Future<T> mutateAsync(V variables) => _mutation.mutateAsync(variables);

  /// Fire-and-observe variant — errors surface via [snapshot] rather than a
  /// thrown exception, for widgets that just watch `isError`/`error`.
  void mutate(V variables) => _mutation.mutate(variables);

  void reset() => _mutation.reset();
  void cancel() => _mutation.cancel();

  @override
  void onClose() {
    _mutation.removeListener(_onChange);
    _mutation.dispose();
    super.onClose();
  }
}
