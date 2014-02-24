library di.transformer.options;

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;

/** Options used by DI transformers */
class TransformOptions {

  /**
   * The file path of the primary Dart entry point (main) for the application.
   * This is used as the starting point to find all injectable types used by the
   * application.
   */
  final String dartEntry;

  /**
   * List of additional annotations which are used to indicate types as being
   * injectable.
   */
  final List<String> injectableAnnotations;

  /**
   * Set of additional types which should be injected.
   */
  final Set<String> injectedTypes;

  /**
   * Path to the Dart SDK directory, for resolving Dart libraries.
   */
  final String sdkDirectory;

  TransformOptions({String dartEntry, String sdkDirectory,
      List<String> injectableAnnotations, List<String> injectedTypes})
    : dartEntry = _systemToAssetPath(dartEntry),
      sdkDirectory = sdkDirectory,
      injectableAnnotations =
          injectableAnnotations != null ? injectableAnnotations : [],
      injectedTypes =
          new Set.from(injectedTypes != null ? injectedTypes : []) {
    if (sdkDirectory == null)
      throw new ArgumentError('sdkDirectory must be provided.');
  }

  // Don't need to check package as transformers only run for primary package.
  bool isDartEntry(AssetId id) => id.path == dartEntry || dartEntry == '*';
}

/** Convert system paths to asset paths (asset paths are posix style). */
String _systemToAssetPath(String assetPath) {
  if (path.Style.platform != path.Style.windows) return assetPath;
  return path.posix.joinAll(path.split(assetPath));
}
