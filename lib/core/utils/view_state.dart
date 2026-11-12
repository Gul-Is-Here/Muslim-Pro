/// UI state of one async operation. `messageKey` is a translation key, never raw text.
sealed class ViewState<T> {
  const ViewState();
}

final class Idle<T> extends ViewState<T> {
  const Idle();
}

final class Loading<T> extends ViewState<T> {
  const Loading();
}

final class Success<T> extends ViewState<T> {
  const Success(this.data);
  final T data;
}

final class Empty<T> extends ViewState<T> {
  const Empty();
}

final class ViewError<T> extends ViewState<T> {
  const ViewError(this.messageKey);
  final String messageKey;
}
