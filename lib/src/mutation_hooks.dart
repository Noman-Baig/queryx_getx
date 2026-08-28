import 'package:get/get.dart';
import 'package:queryx/queryx.dart';

import 'mutation_controller.dart';
import 'queryx_client_binding.dart';

/// Gets or creates the [MutationxController] registered under [tag].
///
/// Unlike [useQuery], [tag] is required rather than derived from a key —
/// mutations don't have one intrinsic identity the way a cached resource
/// does (`['users']` names a resource; "create a user" doesn't name
/// itself). Pick a tag that's stable for the screen/form it belongs to,
/// e.g. `'create-user-form'`.
///
/// Because `queryxClient` is reachable globally via GetX's DI, mutation
/// lifecycle callbacks don't need anything analogous to `queryx_riverpod`'s
/// `optionsBuilder(ref)` — just reference `queryxClient` directly:
///
/// ```dart
/// final controller = useMutation<int, void, int>(
///   'like-post-1',
///   (_) => api.post('/posts/1/like'),
///   options: MutationOptions(
///     onMutate: (_) async {
///       final snapshot = queryxClient.getQueryData<int>(likesKey)!;
///       queryxClient.updateQueryData<int>(likesKey, (n) => (n ?? 0) + 1);
///       return snapshot;
///     },
///     onSuccess: (serverCount, _, __) => queryxClient.setQueryData(likesKey, serverCount),
///     onError: (error, _, snapshot) => queryxClient.setQueryData(likesKey, snapshot!),
///   ),
/// );
///
/// ElevatedButton(
///   onPressed: () => controller.mutate(null),
///   child: const Icon(Icons.favorite),
/// )
/// ```
MutationxController<T, V, C> useMutation<T, V, C>(
  String tag,
  MutationFn<T, V> fn, {
  MutationOptions<T, V, C>? options,
  QueryClient? client,
}) {
  if (Get.isRegistered<MutationxController<T, V, C>>(tag: tag)) {
    return Get.find<MutationxController<T, V, C>>(tag: tag);
  }
  final resolvedClient = client ?? queryxClient;
  final mutation = resolvedClient.mutation<T, V, C>(fn, options: options);
  return Get.put<MutationxController<T, V, C>>(
    MutationxController<T, V, C>(mutation),
    tag: tag,
  );
}

/// Releases the GetX-registered mutation controller for [tag]. Safe to
/// call even if nothing is registered.
void disposeMutation<T, V, C>(String tag) {
  if (Get.isRegistered<MutationxController<T, V, C>>(tag: tag)) {
    Get.delete<MutationxController<T, V, C>>(tag: tag);
  }
}
