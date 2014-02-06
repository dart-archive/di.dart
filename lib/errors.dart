part of di;

class InvalidBindingError extends ArgumentError {
  InvalidBindingError(message) : super(message);
}

class NoProviderError extends ArgumentError {
  NoProviderError(message) : super(message);
}

class CircularDependencyError extends ArgumentError {
  CircularDependencyError(message) : super(message);
}

class IllegalOperationError extends ArgumentError {
  IllegalOperationError(message): super(message);
}
