import 'package:get/get.dart';
import 'package:queryx/queryx.dart';

import 'infinite_query_controller.dart';

/// Gets or creates the [InfiniteQueryxController] for [key], registering it
/// with GetX's DI under `tag ?? key.id`. Unlike [useQuery], this doesn't go
/// through the [QueryClient]'s registry — `InfiniteQuery` manages its own
/// pages independently — but the same-key sharing behavior at the GetX
/// controller level is identical.
///
/// ```dart
/// final feed = useInfiniteQuery<Post, int>(
///   QueryKey(['posts']),
///   initialPageParam: 0,
///   fetchPage: (page) => api.getPosts(page: page ?? 0),
/// );
///
/// Obx(() => ListView.builder(
///   itemCount: feed.value.items.length + 1,
///   itemBuilder: (context, i) {
///     if (i == feed.value.items.length) {
///       feed.fetchNextPage();
///       return const CircularProgressIndicator();
///     }
///     return PostTile(feed.value.items[i]);
///   },
/// ));
/// ```
InfiniteQueryxController<T, P> useInfiniteQuery<T, P>(
  QueryKey key, {
  required PageFetcher<T, P> fetchPage,
  P? initialPageParam,
  String? tag,
}) {
  final controllerTag = tag ?? key.id;
  if (Get.isRegistered<InfiniteQueryxController<T, P>>(tag: controllerTag)) {
    return Get.find<InfiniteQueryxController<T, P>>(tag: controllerTag);
  }
  final query = InfiniteQuery<T, P>(
    key: key,
    initialPageParam: initialPageParam,
    fetchPage: fetchPage,
  );
  return Get.put<InfiniteQueryxController<T, P>>(
    InfiniteQueryxController<T, P>(query),
    tag: controllerTag,
  );
}

/// Releases the GetX-registered infinite-query controller for [key] (or
/// [tag]). Safe to call even if nothing is registered.
void disposeInfiniteQuery<T, P>(QueryKey key, {String? tag}) {
  final controllerTag = tag ?? key.id;
  if (Get.isRegistered<InfiniteQueryxController<T, P>>(tag: controllerTag)) {
    Get.delete<InfiniteQueryxController<T, P>>(tag: controllerTag);
  }
}
