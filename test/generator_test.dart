import 'dart:io';
import 'package:analyzer/analyzer.dart';
import 'package:di/generator.dart' as generator;
import 'package:guinness/guinness.dart';
import 'package:matcher/matcher.dart' as matcher;

main(args) {

  describe('generator', () {

    it('should codesplit deferred libraries', () {
      Map<generator.Chunk, String> code = generator.generateCode(
          'test_assets/gen_test1/main.dart', ['annotations.InjectableTest'],
          Platform.environment['DART_SDK'], [Platform.packageRoot], 'main.dart');

      expect(code.keys.map((chunk) => chunk.library == null ? null : chunk.library.name))
          .to(matcher.unorderedEquals([null, 'lib_a', 'lib_b', 'lib_c']));

      code.forEach((chunk, code) {
        var cu = parseCompilationUnit(code);
        if (chunk.library == null) {
          expectHasImports(cu, ['main.dart', 'common1.dart']);
        } else if (chunk.library.name.endsWith('lib_a')) {
          expectHasImports(cu, ['a.dart', 'a2.dart', 'common2.dart']);
        } else if (chunk.library.name.endsWith('lib_b')) {
          expectHasImports(cu, ['b.dart', 'b2.dart', 'common2.dart']);
        } else if (chunk.library.name.endsWith('lib_c')) {
          expectHasImports(cu, []);
        }
      });
    });
  });
}

expectHasImports(CompilationUnit cu, List<String> expectedImports) {
  var imports = <String>[];
  cu.directives.forEach((Directive directive) {
    if (directive is NamespaceDirective) {
      // 'Only expecting import, no exports.'
      expect(directive).toBeAnInstanceOf(ImportDirective);
      ImportDirective import = directive;
      imports.add(import.uri.stringValue);
    }
  });
  expect(imports.length).toEqual(expectedImports.length);
  for (int i = 0; i < imports.length; i++) {
    expect(imports[i]).to(matcher.endsWith(expectedImports[i]));
  }
}
