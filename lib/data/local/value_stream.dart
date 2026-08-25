import 'dart:async';

/// A broadcast stream that replays its latest value to every new listener.
///
/// The repositories expose `Stream`s so the UI stays reactive, but a widget
/// that subscribes late must not wait for the next write to render. Rather than
/// pull in `rxdart` for one behaviour, this is the 30 lines that behaviour
/// actually needs.
class ValueStream<T> {
  ValueStream(this._value);

  T _value;
  final StreamController<T> _controller = StreamController<T>.broadcast();

  T get value => _value;

  Stream<T> get stream async* {
    yield _value;
    yield* _controller.stream;
  }

  bool get hasListeners => _controller.hasListener;

  void add(T next) {
    _value = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  /// Re-emits the current value — used after a batch of mutations that changed
  /// the underlying collection in place.
  void refresh() => add(_value);

  Future<void> close() => _controller.close();
}
