part of di;

class NoProviderError extends ArgumentError {
  NoProviderError(message) : super(message);
}

class CircularDependencyError extends ArgumentError {
  CircularDependencyError(message) : super(message);
}

class OverrideError extends ArgumentError {
  OverrideError(message) : super(message);
}
