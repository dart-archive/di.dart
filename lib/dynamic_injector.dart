library di.dynamic_injector;

import 'di.dart';
export 'di.dart';

/**
 * A backwards-compatible shim to avoid breaking DI 1 with DI 2.0.0
 * TODO: Remove after all apps have been upgraded.
 */
@Deprecated("3.0")
class DynamicInjector extends ModuleInjector {
	DynamicInjector({modules}) : super(modules);
}
