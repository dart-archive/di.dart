import 'package:analyzer_experimental/src/generated/java_io.dart';
import 'package:analyzer_experimental/src/generated/source_io.dart';
import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer_experimental/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer_experimental/src/generated/element.dart';
import 'package:analyzer_experimental/src/generated/engine.dart';

import 'dart:io';

const String PACKAGE_PREFIX = 'package:';
const String DART_PACKAGE_PREFIX = 'dart:';

main() {
  var args = new Options().arguments;
  if (args.length < 5) {
    print('Usage: generator path_to_sdk file_to_resolve annotations output package_roots+');
    exit(0);
  }

  var pathToSdk = args[0];
  var entryPoint = args[1];
  var classAnnotations = args[2].split(',');
  var output = args[3];
  var packageRoots = args.sublist(4);

  print('pathToSdk: $pathToSdk');
  print('entryPoint: $entryPoint');
  print('classAnnotations: $classAnnotations');
  print('output: $output');
  print('packageRoots: $packageRoots');

  var c = new SourceCrawler(pathToSdk, packageRoots);
  List<String> imports = <String>[];
  List<ClassElement> typeFactoryTypes = <ClassElement>[];
  Map<String, String> typeToImport = new Map<String, String>();
  c.crawl(entryPoint, (CompilationUnit compilationUnit, SourceFile source) {
    compilationUnit.accept(
        new CompilationUnitVisitor(source, classAnnotations, imports,
            typeToImport, typeFactoryTypes));
  });
  var code = printLibraryCode(typeToImport, imports, typeFactoryTypes);
  new File(output).writeAsStringSync(code);
}

String printLibraryCode(Map<String, String> typeToImport, List<String> imports,
                      List<ClassElement> typeFactoryTypes) {
  List<String> requiredImports = <String>[];
  StringBuffer factories = new StringBuffer();

  String resolveClassIdentifier(InterfaceType type) {
    if ((type.element as ClassElement).library.isDartCore) {
      return type.name;
    }
    String import = typeToImport[getCanonicalName(type)];
    if (!requiredImports.contains(import)) {
      requiredImports.add(import);
    }
    return 'import_${imports.indexOf(import)}.${type.name}';
  }

  typeFactoryTypes.forEach((ClassElement clazz) {
    factories.write('typeFactories[${resolveClassIdentifier(clazz.type)}] = (f) => ');
    factories.write('new ${resolveClassIdentifier(clazz.type)}(');
    ConstructorElement constr =
        clazz.constructors.firstWhere((c) => c.name.isEmpty);
    factories.write(constr.parameters.map((param) =>
        'f(${resolveClassIdentifier(param.type)})').join(', '));
    factories.write(');\n');
  });
  StringBuffer code = new StringBuffer();
  code.write('library di.generated.type_factories;\n');
  requiredImports.forEach((import) {
    code.write ('import "$import" as import_${imports.indexOf(import)};\n');
  });
  code.write('var typeFactories = new Map<Type, Function>();\n');
  code.write('main() {\n');
  code.write(factories);
  code.write('}\n');

  return code.toString();
}

class CompilationUnitVisitor extends GeneralizingASTVisitor {
  List<String> imports;
  Map<String, String> typeToImport;
  List<ClassElement> typeFactoryTypes;
  List<String> classAnnotations;
  SourceFile source;

  CompilationUnitVisitor(this.source, this.classAnnotations, this.imports,
      this.typeToImport, this.typeFactoryTypes);

  visitLibraryDirective(LibraryDirective library) {
    LibraryElement libElement = library.element;
    int annotationIdx = 0;
    for (ElementAnnotation ann in libElement.metadata) {
      if (ann.element is ConstructorElement) {
        ConstructorElement con = ann.element;
        if (getQualifiedName(con.enclosingElement.type) == 'di.annotations.Injectables') {
          var listLiteral =
              library.metadata[annotationIdx].arguments.arguments.first;
          for (Expression element in listLiteral.elements) {
            typeFactoryTypes
                .add((element as SimpleIdentifier).element as ClassElement);
          }
        }
      }
      annotationIdx++;
    }
    return super.visitLibraryDirective(library);
  }

  visitClassDeclaration(ClassDeclaration classDecl) {
    if (classDecl.name.name.startsWith('_')) {
      return; // ignore private classes.
    }
    typeToImport[getCanonicalName(classDecl.element.type)] =
        source.entryPointImport;
    if (!imports.contains(source.entryPointImport)) {
      imports.add(source.entryPointImport);
    }

    for (ElementAnnotation ann in classDecl.element.metadata) {
      if (ann.element is ConstructorElement) {
        ConstructorElement con = ann.element;
        if (classAnnotations
            .contains(getQualifiedName(con.enclosingElement.type))) {
          typeFactoryTypes.add(classDecl.element);
        }
      }
    }

    return super.visitCompilationUnitMember(classDecl);
  }
}

String getQualifiedName(InterfaceType type) {
  var lib = type.element.library.displayName;
  var name = type.name;
  return lib == null ? name : '$lib.$name';
}

String getCanonicalName(InterfaceType type) {
  var source = type.element.source.toString();
  var name = type.name;
  return '$source:$name';
}

typedef CompilationUnitCrawler(CompilationUnit compilationUnit,
                               SourceFile source);

class SourceCrawler {
  final List<String> packageRoots;
  final String sdkPath;

  SourceCrawler(this.sdkPath, this.packageRoots);

  void crawl(String entryPoint, CompilationUnitCrawler _visitor) {
    JavaSystemIO.setProperty("com.google.dart.sdk", sdkPath);
    DartSdk sdk = DirectoryBasedDartSdk.defaultSdk;

    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    var packageUriResolver = new PackageUriResolver(packageRoots.map((pr) =>
          new JavaFile.fromUri(new Uri.file(pr))));
    context.sourceFactory = new SourceFactory.con2([
      new DartUriResolver(sdk),
      new FileUriResolver(),
      packageUriResolver
    ]);

    var entryPointFile;
    var entryPointImport;
    if (entryPoint.startsWith(PACKAGE_PREFIX)) {
      entryPointFile = new JavaFile(packageUriResolver
          .resolveAbsolute(context.sourceFactory.contentCache,
              Uri.parse(entryPoint)).toString());
      entryPointImport = entryPoint;
    } else {
      entryPointFile = new JavaFile(entryPoint);
      entryPointImport = entryPointFile.getAbsolutePath();
    }

    Source source = new FileBasedSource.con1(
        context.sourceFactory.contentCache, entryPointFile);
    ChangeSet changeSet = new ChangeSet();
    changeSet.added(source);
    context.applyChanges(changeSet);
    LibraryElement rootLib = context.computeLibraryElement(source);
    CompilationUnit resolvedUnit =
        context.resolveCompilationUnit(source, rootLib);

    var sourceFile = new SourceFile(
        entryPointFile.getAbsolutePath(),
        entryPointImport,
        resolvedUnit);
    List<SourceFile> visited = <SourceFile>[];
    List<SourceFile> toVisit = <SourceFile>[sourceFile];

    while (toVisit.isNotEmpty) {
      SourceFile currentFile = toVisit.removeAt(0);
      visited.add(currentFile);
      _visitor(currentFile.compilationUnit, currentFile);
      var visitor = new CrawlerVisitor(currentFile, context);
      currentFile.compilationUnit.accept(visitor);
      visitor.toVisit.forEach((SourceFile todo) {
        if (!toVisit.contains(todo) && !visited.contains(todo)) {
          toVisit.add(todo);
        }
      });
    }
  }
}

class CrawlerVisitor extends GeneralizingASTVisitor {
  List<SourceFile> toVisit = <SourceFile>[];
  SourceFile currentFile;
  AnalysisContext context;
  String currentDir;

  CrawlerVisitor(this.currentFile, this.context);

  visitImportDirective(ImportDirective node) {
    _doImport(node);
    super.visitImportDirective(node);
  }

  visitPartDirective(PartDirective node) {
    _doImport(node);
    super.visitPartDirective(node);
  }

  _doImport(UriBasedDirective node) {
    Source source;
    bool isPart = false;
    if (node.uriElement is LibraryElement) { // import
      var libElement = node.uriElement as LibraryElement;
      source = libElement.definingCompilationUnit.source;
    } else if (node.uriElement is CompilationUnitElement) { // part
      isPart = true;
      source = (node.uriElement as CompilationUnitElement).source;
    }

    bool isSystem = false;
    String systemImport;
    String uri = node.uri.stringValue;
    if (uri.startsWith(DART_PACKAGE_PREFIX)) {
      isSystem = true;
      systemImport = uri;
    } else if (currentFile.entryPointImport.startsWith(DART_PACKAGE_PREFIX)) {
      isSystem = true;
      systemImport = currentFile.entryPointImport;
    }
    // check if it's some internal hidden library
    if (isSystem &&
        systemImport.substring(DART_PACKAGE_PREFIX.length).startsWith('_')) {
      return;
    }

    var nextCompilationUnit = context
        .resolveCompilationUnit(source, context.computeLibraryElement(source));
    if (uri.startsWith(PACKAGE_PREFIX)) {
      toVisit.add(new SourceFile(source.toString(), uri, nextCompilationUnit));
    } else { // relative import.
      var newImport;
      if (isSystem) {
        newImport = systemImport; // original uri
      } else if (isPart) {
        newImport = currentFile.entryPointImport;
      } else {
        // relative import
        String import = currentFile.entryPointImport.
            substring(0, currentFile.entryPointImport.lastIndexOf('/'));
        var currentDir = new File(currentFile.canonicalPath).directory.path;
        if (uri.startsWith('../')) {
          while (uri.startsWith('../')) {
            uri = uri.substring('../'.length);
            import = import.substring(0, import.lastIndexOf('/'));
            currentDir = currentDir.substring(0, currentDir.lastIndexOf('/'));
          }
        }
        newImport = '$import/$uri';
      }
      toVisit.add(
          new SourceFile(source.toString(), newImport, nextCompilationUnit));
    }
  }
}

class SourceFile {
  String canonicalPath;
  String entryPointImport;
  CompilationUnit compilationUnit;

  SourceFile(this.canonicalPath, this.entryPointImport, this.compilationUnit);

  operator ==(o) {
    if (o is String) return o == canonicalPath;
    if (o is! SourceFile) return false;
    return o.canonicalPath == canonicalPath;
  }
}
