library di.transformer.module_transformer;

import 'dart:async';
import 'package:barback/barback.dart';

/**
 * Pub transformer that changes reflector in Module to null instead of importing
 * the dynamic reflector which imports mirrors. Another di transformer run by the app
 * will import the static reflector.
 */
class ModuleTransformerGroup implements TransformerGroup {
  final Iterable<Iterable> phases;

  ModuleTransformerGroup.asPlugin(BarbackSettings settings)
      : phases = [[new ModuleTransformer()]];
}

class ModuleTransformer extends Transformer {

  ModuleTransformer();

  Future<bool> isPrimary(AssetId id) =>
    new Future.value(id == new AssetId.parse("di|lib/src/module.dart"));

  Future apply(Transform transform) {
    var id = transform.primaryInput.id;
    return transform.primaryInput.readAsString().then((code) {
      // Note: this rewrite is coupled with how module.dart is
      // written. Make sure both are updated in sync.
      transform.addOutput(new Asset.fromString(id, code
          .replaceAll(new RegExp('import "reflector_dynamic.dart";'),
              'import "reflector_null.dart";')));
    });
  }
}
