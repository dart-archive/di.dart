library unittest;

import 'package:unittest/unittest.dart';
import '../lib/mirrors.dart';

export 'package:unittest/unittest.dart';

// fix the testing framework ;-)
void it(String spec, TestFunction body) => test(spec, body);
void xit(String spec, TestFunction body) {}
void iit(String spec, TestFunction body) => solo_test(spec, body);

Matcher toEqual(expected) => equals(expected);
Matcher toBe(expected) => same(expected);
Matcher instanceOf(Type t) => new IsInstanceOfTypeMatcher(t);

Matcher toThrow(Type exceptionClass, String message) =>
  new ThrowsMatcher(new ComplexExceptionMatcher(instanceOf(exceptionClass), toEqual(message)));

Matcher not(Matcher matcher) => new NegateMatcher(matcher);


class NegateMatcher extends BaseMatcher {
  final Matcher _matcher;

  const NegateMatcher(Matcher matcher) : _matcher = matcher;

  bool matches(obj, MatchState ms) {
    return !_matcher.matches(obj, ms);
  }

  Description describe(Description description) {
    description.add('NOT ');
    return _matcher.describe(description);
  }

  Description describeMismatch(item, Description mismatchDescription, MatchState matchState,
                               bool verbose) {
    return _matcher.describeMismatch(item, mismatchDescription, matchState, verbose);
  }
}


class ThrowsMatcher extends Throws {
  final Matcher _matcher;

  const ThrowsMatcher([Matcher matcher]) : _matcher = matcher, super(matcher);

  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState,
                               bool verbose) {
    if (item is! Function && item is! Future) {
      return mismatchDescription.add(' not a Function or Future');
    }

    if (_matcher == null ||  matchState.state == null) {
      return mismatchDescription.add(' did not throw any exception');
    }

    return _matcher.describeMismatch(item, mismatchDescription, matchState, verbose);
  }
}

class ComplexExceptionMatcher extends BaseMatcher {
  Matcher classMatcher;
  Matcher messageMatcher;

  ComplexExceptionMatcher(this.classMatcher, this.messageMatcher);

  bool matches(obj, MatchState ms) {
    if (!classMatcher.matches(obj, ms)) {
      return false;
    }

    return messageMatcher.matches(obj.message, ms);
  }

  Description describe(Description description) {
    classMatcher.describe(description);

    description.add(' with message ');
    messageMatcher.describe(description);
  }

  Description describeMismatch(item, Description mismatchDescription, MatchState matchState,
                               bool verbose) {
    Exception e = matchState.state['exception'];

    mismatchDescription.add('threw ').addDescriptionOf(e);

    if (reflect(e).members.containsKey('message')) {
      mismatchDescription.add(' with message ').addDescriptionOf(e.message);
    }
  }
}

// Welcome to Dart ;-)
class IsInstanceOfTypeMatcher extends BaseMatcher {
  Type t;
  
  IsInstanceOfTypeMatcher(Type t) {
    this.t = t;
  }
  
  bool matches(obj, MatchState matchState) {
    return reflect(obj).type.qualifiedName == reflectClass(t).qualifiedName;
  }
  
  Description describe(Description description) =>
    description.add('an instance of ${t.toString()}');
}
