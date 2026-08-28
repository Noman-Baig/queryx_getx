# Changelog

## 0.1.0

Initial release.

- `setupQueryxClient` / `queryxClient` — GetX DI registration for the
  shared `QueryClient`.
- `QueryxController<T>`, `MutationxController<T,V,C>`,
  `InfiniteQueryxController<T,P>` — `GetxController`s wrapping
  `Query`/`Mutation`/`InfiniteQuery`, reactive via `.obs` snapshots.
- `useQuery`, `useMutation`, `useInfiniteQuery` helpers that register
  controllers with GetX's DI by tag (defaulting to the query key for
  queries), so multiple widgets requesting the same resource share one
  controller in addition to the dedup queryx already does at the
  `QueryClient` level.
- `disposeQuery` / `disposeMutation` / `disposeInfiniteQuery` for eager
  GetX-level cleanup independent of queryx's own `cacheTime` GC.
- Test suite (`flutter test`): initial fetch, controller sharing by tag,
  QueryClient-level dedup independent of controller tags, invalidation,
  mutation + cache-based optimistic update + rollback, infinite pagination.
