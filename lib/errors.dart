part of di;


class NoProviderException extends ArgumentError {
  NoProviderException(message) : super(message);
}

class CircularDependencyException extends ArgumentError {
  CircularDependencyException(message) : super(message);
}