library di.provider;

import 'injector_delagate.dart';
import 'base_injector.dart';
import 'package:di/di.dart';

abstract class ObjectFactory {
  Object getInstanceByKey(Key key, BaseInjector requester, ResolutionContext resolving);
}

abstract class Provider {
  final Visibility visibility;
  final Type type;

  Provider(this.type, this.visibility);

  dynamic get(BaseInjector injector, BaseInjector requestor,
      ObjectFactory objFactory, ResolutionContext resolving);
}

class ValueProvider extends Provider {
  dynamic value;

  ValueProvider(type, this.value, [Visibility visibility])
      : super(type, visibility);
  
  @override
  dynamic get(BaseInjector injector, BaseInjector requestor,
      ObjectFactory objFactory, ResolutionContext resolving) => value;
}

class TypeProvider extends Provider {
  TypeProvider(type, [Visibility visibility]) : super(type, visibility);

  @override
  dynamic get(BaseInjector injector, BaseInjector requestor,
      ObjectFactory objFactory, ResolutionContext resolving) =>
    injector.newInstanceOf(type, objFactory, requestor, resolving);
}

class FactoryProvider extends Provider {
  final Function factoryFn;

  FactoryProvider(type, this.factoryFn, [Visibility visibility])
      : super(type, visibility);

  @override
  dynamic get(BaseInjector injector, BaseInjector requestor,
      ObjectFactory objFactory, ResolutionContext resolving) =>
    factoryFn(new InjectorDelagate(injector, resolving));
}
