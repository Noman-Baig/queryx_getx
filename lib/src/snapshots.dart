import 'package:queryx/queryx.dart';

/// Immutable snapshot of a [Query]'s state at a point in time — what
/// [QueryxController.snapshot] actually holds. GetX's `Obx` rebuilds
/// whenever this `.obs` value is replaced.
class QueryxSnapshot<T> {
  const QueryxSnapshot({
    required this.data,
    required this.error,
    required this.status,
    required this.isLoading,
    required this.isFetching,
    required this.isRefreshing,
    required this.isStale,
  });

  final T? data;
  final QueryError? error;
  final QueryStatus status;
  final bool isLoading;
  final bool isFetching;
  final bool isRefreshing;
  final bool isStale;

  bool get hasData => data != null && status == QueryStatus.success;
  bool get hasError => error != null && status == QueryStatus.error;

  factory QueryxSnapshot.fromQuery(Query<T> query) => QueryxSnapshot<T>(
        data: query.data,
        error: query.error,
        status: query.status,
        isLoading: query.isLoading,
        isFetching: query.isFetching,
        isRefreshing: query.isRefreshing,
        isStale: query.isStale,
      );

  /// Pattern-match helper for use inside `Obx(() => snapshot.value.when(...))`.
  R when<R>({
    required R Function() loading,
    required R Function(QueryError error) error,
    required R Function(T data) data,
  }) {
    if (hasData) return data(this.data as T);
    if (hasError) return error(this.error!);
    return loading();
  }

  @override
  String toString() =>
      'QueryxSnapshot(status: $status, hasData: $hasData, isFetching: $isFetching)';
}

/// Immutable snapshot of a [Mutation]'s state.
class MutationSnapshot<T> {
  const MutationSnapshot({
    required this.data,
    required this.error,
    required this.status,
  });

  final T? data;
  final QueryError? error;
  final QueryStatus status;

  bool get isIdle => status == QueryStatus.idle;
  bool get isLoading => status == QueryStatus.loading;
  bool get isSuccess => status == QueryStatus.success;
  bool get isError => status == QueryStatus.error;

  factory MutationSnapshot.fromMutation(
          Mutation<T, dynamic, dynamic> mutation) =>
      MutationSnapshot<T>(
        data: mutation.data,
        error: mutation.error,
        status: mutation.status,
      );

  @override
  String toString() => 'MutationSnapshot(status: $status)';
}

/// Immutable snapshot of an [InfiniteQuery]'s state.
class InfiniteQueryxSnapshot<T, P> {
  const InfiniteQueryxSnapshot({
    required this.items,
    required this.error,
    required this.isLoading,
    required this.isFetchingNextPage,
    required this.isFetchingPreviousPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  final List<T> items;
  final QueryError? error;
  final bool isLoading;
  final bool isFetchingNextPage;
  final bool isFetchingPreviousPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  bool get hasError => error != null;

  factory InfiniteQueryxSnapshot.fromInfiniteQuery(InfiniteQuery<T, P> q) =>
      InfiniteQueryxSnapshot<T, P>(
        items: q.items,
        error: q.error,
        isLoading: q.isLoading,
        isFetchingNextPage: q.isFetchingNextPage,
        isFetchingPreviousPage: q.isFetchingPreviousPage,
        hasNextPage: q.hasNextPage,
        hasPreviousPage: q.hasPreviousPage,
      );

  @override
  String toString() =>
      'InfiniteQueryxSnapshot(items: ${items.length}, hasNextPage: $hasNextPage)';
}
