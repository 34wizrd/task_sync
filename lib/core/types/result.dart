// lib/core/types/result.dart
class Result<T, E> {
  final T? data;
  final E? error;
  const Result._({this.data, this.error});
  bool get isOk => data != null && error == null;

  factory Result.ok(T data) => Result._(data: data);
  factory Result.err(E error) => Result._(error: error);
}
