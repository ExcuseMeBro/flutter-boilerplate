/// Shares only overlapping reads, never retains a completed value. Writes are
/// ordered and invalidate in-flight reads, including reads started before them.
/// All writes to this value must use [write]; external changes are seen on the
/// next non-overlapping read (no process-lifetime credential/locale cache).
class CoalescedRead<T> {
  CoalescedRead(this._load);

  final Future<T> Function() _load;
  Future<T>? _pending;
  Future<void> _writes = Future<void>.value();
  int _generation = 0;

  Future<T> read() => _pending ??= _read(_generation);

  Future<T> _read(int generation) async {
    try {
      await _writes;
      final value = await _load();
      if (generation != _generation) return await read();
      return value;
    } finally {
      if (generation == _generation) _pending = null;
    }
  }

  Future<void> write(Future<void> Function() action) {
    _generation++;
    _pending = null;
    final result = _writes.then((_) => action());
    // A failed write must reach its caller, but not poison subsequent reads or
    // writes. Reads reload the persisted value rather than assuming success.
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
