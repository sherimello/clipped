import 'package:flutter/material.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum CodeLanguage {
  dart, python, javascript, typescript, html, css, json,
  sql, java, cpp, go, rust, shell, yaml, kotlin, swift, unknown,
}

enum CodeFramework {
  flutter, react, vue, angular, nextjs, django, flask, spring, express, none,
}

// ─── CodeInfo ─────────────────────────────────────────────────────────────────

class CodeInfo {
  final CodeLanguage language;
  final CodeFramework framework;

  const CodeInfo({required this.language, this.framework = CodeFramework.none});

  String get languageLabel => switch (language) {
    CodeLanguage.dart       => 'Dart',
    CodeLanguage.python     => 'Python',
    CodeLanguage.javascript => 'JS',
    CodeLanguage.typescript => 'TS',
    CodeLanguage.html       => 'HTML',
    CodeLanguage.css        => 'CSS',
    CodeLanguage.json       => 'JSON',
    CodeLanguage.sql        => 'SQL',
    CodeLanguage.java       => 'Java',
    CodeLanguage.cpp        => 'C++',
    CodeLanguage.go         => 'Go',
    CodeLanguage.rust       => 'Rust',
    CodeLanguage.shell      => 'Shell',
    CodeLanguage.yaml       => 'YAML',
    CodeLanguage.kotlin     => 'Kotlin',
    CodeLanguage.swift      => 'Swift',
    CodeLanguage.unknown    => 'Code',
  };

  String get frameworkLabel => switch (framework) {
    CodeFramework.flutter => 'Flutter',
    CodeFramework.react   => 'React',
    CodeFramework.vue     => 'Vue',
    CodeFramework.angular => 'Angular',
    CodeFramework.nextjs  => 'Next.js',
    CodeFramework.django  => 'Django',
    CodeFramework.flask   => 'Flask',
    CodeFramework.spring  => 'Spring',
    CodeFramework.express => 'Express',
    CodeFramework.none    => '',
  };

  String get displayLabel {
    final fw = frameworkLabel;
    return fw.isEmpty ? languageLabel : '$languageLabel · $fw';
  }

  Color get accentColor => switch (language) {
    CodeLanguage.dart       => const Color(0xFF00B4D8),
    CodeLanguage.python     => const Color(0xFF4B8BF5),
    CodeLanguage.javascript => const Color(0xFFF0DB4F),
    CodeLanguage.typescript => const Color(0xFF3178C6),
    CodeLanguage.html       => const Color(0xFFE44D26),
    CodeLanguage.css        => const Color(0xFF264DE4),
    CodeLanguage.json       => const Color(0xFFCBCB41),
    CodeLanguage.sql        => const Color(0xFF00758F),
    CodeLanguage.java       => const Color(0xFFED8B00),
    CodeLanguage.cpp        => const Color(0xFF00599C),
    CodeLanguage.go         => const Color(0xFF00ACD7),
    CodeLanguage.rust       => const Color(0xFFCE412B),
    CodeLanguage.shell      => const Color(0xFF89E051),
    CodeLanguage.yaml       => const Color(0xFFCB171E),
    CodeLanguage.kotlin     => const Color(0xFF7F52FF),
    CodeLanguage.swift      => const Color(0xFFFA7343),
    CodeLanguage.unknown    => const Color(0xFF9CA3AF),
  };
}

// ─── CodeDetector ─────────────────────────────────────────────────────────────

class CodeDetector {
  static CodeInfo? detect(String text) {
    final t = text.trim();
    if (t.length < 15) return null;

    // Penalize natural language prose: many sentence-endings without braces.
    int prosePenalty = 0;
    final sentenceCount = RegExp(r'[.!?][ \n]').allMatches(t).length;
    final hasBraces = t.contains('{') || t.contains('}');
    if (sentenceCount >= 4 && !hasBraces) prosePenalty += 3;
    if (sentenceCount >= 8) prosePenalty += 3;

    int bestScore = 0;
    CodeLanguage best = CodeLanguage.unknown;

    for (final lang in CodeLanguage.values) {
      if (lang == CodeLanguage.unknown) continue;
      final s = _score(t, lang);
      if (s > bestScore) {
        bestScore = s;
        best = lang;
      }
    }

    if (bestScore - prosePenalty < 7) return null;
    return CodeInfo(language: best, framework: _framework(t, best));
  }

  // ── Scoring ────────────────────────────────────────────────────────────────

  static int _score(String t, CodeLanguage l) {
    int s = 0;
    if (t.contains('\n')) s += 1;

    switch (l) {
      case CodeLanguage.dart:
        s += _has(t, "import 'package:") * 6;
        s += _has(t, 'import "package:') * 6;
        s += _has(t, 'StatelessWidget') * 6;
        s += _has(t, 'StatefulWidget') * 6;
        s += _has(t, 'BuildContext') * 5;
        s += _has(t, 'Widget ') * 3;
        s += _has(t, 'void main()') * 4;
        s += _has(t, 'Future<void>') * 3;
        s += _has(t, '@override') * 3;
        s += _has(t, 'dart:') * 4;
        s += _rx(t, r'\bconst\s+\w+\s*\(') * 2;
        s += _rx(t, r'\bclass\s+\w+\s+(extends|implements)\b') * 3;
        if (t.contains('=>') && !t.contains('->')) s += 1;

      case CodeLanguage.python:
        s += _rx(t, r'\bdef\s+\w+\s*\(') * 5;
        s += _rx(t, r'\b(from|import)\s+\w+') * 3;
        s += _has(t, 'elif ') * 6;
        s += _has(t, '__init__') * 4;
        s += _has(t, '__name__') * 3;
        s += _has(t, 'self.') * 4;
        s += _rx(t, r':\s*\n') * 2;
        s += _has(t, 'print(') * 2;
        if (t.contains('True') || t.contains('False') || t.contains('None')) s += 2;
        if (t.contains('\n') && !t.contains('{')) s += 1;

      case CodeLanguage.javascript:
        s += _rx(t, r'\b(const|let|var)\s+\w+\s*=') * 3;
        s += _has(t, 'console.log') * 5;
        s += _rx(t, r'\bfunction\s+\w+\s*\(') * 4;
        if (t.contains('=>')) s += 2;
        s += _rx(t, r'\brequire\s*\(') * 4;
        s += _has(t, 'module.exports') * 5;
        if (t.contains('document.') || t.contains('window.')) s += 3;
        if (t.contains('===') || t.contains('!==')) s += 3;
        s += _rx(t, r'import\s+\S+\s+from\s') * 3;
        // penalise TypeScript-specific syntax
        s -= _rx(t, r':\s*(string|number|boolean|any|void)\b') * 3;
        s -= _rx(t, r'\binterface\s+\w+') * 3;

      case CodeLanguage.typescript:
        s += _rx(t, r'\b(const|let|var)\s+\w+\s*=') * 2;
        s += _rx(t, r':\s*(string|number|boolean|any|void|never)\b') * 5;
        s += _rx(t, r'\binterface\s+\w+') * 6;
        s += _rx(t, r'\btype\s+\w+\s*=') * 5;
        s += _has(t, 'import type') * 5;
        s += _rx(t, r'\bexport\s+(default|const|function|class|interface|type)\b') * 3;
        if (t.contains('===') || t.contains('!==')) s += 2;
        s += _rx(t, r'<[A-Z]\w*>') * 2;

      case CodeLanguage.html:
        s += _rx(t, r'<!DOCTYPE\s+html', ci: true) * 10;
        s += _rx(t, r'<html\b', ci: true) * 6;
        s += _rx(t, r'<(head|body|div|span|p|h[1-6]|script|style|form|input|button)\b', ci: true) * 4;
        s += _has(t, '</') * 3;
        s += _rx(t, r'\bclass=') * 2;
        s += _rx(t, r'\bid=') * 2;

      case CodeLanguage.css:
        s += _rx(t, r'@(media|keyframes|import|charset)\b') * 6;
        s += _rx(t, r'\.[a-z][a-z0-9_-]*\s*\{') * 5;
        s += _rx(t, r'#[a-z][a-z0-9_-]*\s*\{') * 4;
        s += _rx(t, r'\b(color|background|font-size|margin|padding|display|flex|grid|border|width|height|position)\s*:') * 4;
        s += _rx(t, r'\d+(px|em|rem|vh|vw|%)\b') * 3;
        if (t.contains('{') && t.contains('}') && t.contains(':') && t.contains(';')) s += 3;
        if (t.contains('function') || t.contains('import ') || t.contains('//')) s -= 5;

      case CodeLanguage.json:
        final trimmed = t.trim();
        if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
            (trimmed.startsWith('[') && trimmed.endsWith(']'))) { s += 4; }
        s += _rx(t, r'"[\w\-]+"\s*:') * 5;
        if (t.contains('//') || t.contains('#') || t.contains('function') || t.contains('import')) s -= 5;

      case CodeLanguage.sql:
        final u = t.toUpperCase();
        if (u.contains('SELECT ') && u.contains(' FROM ')) s += 8;
        if (u.contains('INSERT INTO ')) s += 7;
        if (u.contains('UPDATE ') && u.contains(' SET ')) s += 7;
        if (u.contains('CREATE TABLE') || u.contains('CREATE DATABASE')) s += 8;
        if (u.contains('DROP TABLE') || u.contains('DROP DATABASE')) s += 7;
        if (u.contains('WHERE ')) s += 3;
        if (u.contains('ORDER BY') || u.contains('GROUP BY')) s += 5;
        if (u.contains(' JOIN ')) s += 5;

      case CodeLanguage.java:
        s += _rx(t, r'\bpublic\s+class\s+\w+') * 6;
        if (t.contains('System.out.println') || t.contains('System.out.print')) s += 6;
        s += _rx(t, r'\bimport\s+java\.') * 7;
        if (t.contains('@Override') || t.contains('@Autowired') || t.contains('@Component')) s += 4;
        s += _rx(t, r'\bpublic\s+static\s+void\s+main\s*\(') * 7;
        if (t.contains('String[]') || t.contains('ArrayList<') || t.contains('HashMap<')) s += 4;

      case CodeLanguage.cpp:
        s += _rx(t, r'#include\s*[<"]') * 7;
        s += _rx(t, r'\bint\s+main\s*\(') * 5;
        if (t.contains('std::') || t.contains('cout <<') || t.contains('cin >>')) s += 5;
        if (t.contains('nullptr') || t.contains('NULL')) s += 3;
        if (t.contains('->') && t.contains('::')) s += 3;
        if (t.contains('printf(') || t.contains('scanf(')) s += 4;
        if (t.contains('#define ') || t.contains('#pragma')) s += 4;
        if (t.contains('template<') || t.contains('typename ')) s += 5;

      case CodeLanguage.go:
        s += _rx(t, r'\bpackage\s+\w+') * 7;
        s += _rx(t, r'\bfunc\s+\w+\s*\(') * 5;
        s += _rx(t, r'\bimport\s*\(') * 6;
        if (t.contains('fmt.Println') || t.contains('fmt.Printf') || t.contains('fmt.Sprintf')) s += 6;
        s += _has(t, ':=') * 6;
        if (t.contains('goroutine') || t.contains('chan ') || t.contains('go func')) s += 5;
        if (t.contains('defer ') || t.contains('panic(')) s += 4;

      case CodeLanguage.rust:
        s += _rx(t, r'\bfn\s+\w+\s*\(') * 5;
        s += _rx(t, r'\blet\s+mut\s+\w+') * 5;
        s += _rx(t, r'\buse\s+\w+::') * 6;
        if (t.contains('impl ') || t.contains('trait ')) s += 5;
        if (t.contains('match ') && t.contains('=>')) s += 5;
        if (t.contains('&str') || t.contains('&mut') || t.contains('&self')) s += 5;
        if (t.contains('Result<') || t.contains('Option<')) s += 4;
        if (t.contains('println!') || t.contains('vec![')) s += 5;

      case CodeLanguage.shell:
        s += _rx(t, r'#!/') * 8;
        s += _rx(t, r'\becho\s') * 4;
        s += _rx(t, r'\bif\s+\[') * 5;
        s += _rx(t, r'\b(fi|done|esac)\b') * 5;
        s += _rx(t, r'\$\{?\w+\}?') * 4;
        if (t.contains('grep ') || t.contains('awk ') || t.contains('sed ') || t.contains('chmod ')) s += 3;

      case CodeLanguage.yaml:
        s += _has(t, '---') * 7;
        // Only count keys at line-start — "word: value" mid-sentence is prose, not YAML
        final kvCount = RegExp(r'^\w[\w-]*:\s', multiLine: true).allMatches(t).length;
        if (kvCount >= 1) s += 3;
        if (kvCount >= 4) s += 3;
        if (kvCount >= 7) s += 3;
        s += _rx(t, r'^\s{2,}\w[\w-]*:\s', ml: true) * 4; // indented/nested keys
        s += _rx(t, r'^\s*-\s+\S', ml: true) * 2;
        if (t.contains('{') || t.contains(';') || t.contains('function')) s -= 5;

      case CodeLanguage.kotlin:
        s += _rx(t, r'\bfun\s+\w+\s*\(') * 6;
        s += _rx(t, r'\b(val|var)\s+\w+\s*[=:]') * 4;
        s += _has(t, 'data class ') * 7;
        if (t.contains('companion object') || t.contains('sealed class ')) s += 6;
        if (t.contains('override fun') || t.contains('suspend fun')) s += 6;
        s += _rx(t, r'\bimport\s+kotlin\.') * 7;
        if (t.contains('when (') || t.contains('when{')) s += 5;

      case CodeLanguage.swift:
        s += _rx(t, r'\bfunc\s+\w+\s*\(') * 5;
        s += _rx(t, r'\bguard\s+.*\belse\s*\{') * 7;
        s += _rx(t, r'\bimport\s+(UIKit|SwiftUI|Foundation|AppKit|Combine)\b') * 8;
        if (t.contains('@IBOutlet') || t.contains('@IBAction') || t.contains('@Published') || t.contains('@State')) s += 7;
        if (t.contains('guard let') || t.contains('if let') || t.contains('guard var')) s += 5;
        if (t.contains('var body') && t.contains('struct ')) s += 6;
        if (t.contains('override func') || t.contains('deinit')) s += 3;

      case CodeLanguage.unknown:
        break;
    }

    return s < 0 ? 0 : s;
  }

  static int _has(String t, String p) => t.contains(p) ? 1 : 0;

  static int _rx(String t, String pattern, {bool ml = false, bool ci = false}) =>
      RegExp(pattern, multiLine: ml, caseSensitive: !ci).hasMatch(t) ? 1 : 0;

  // ── Framework detection ────────────────────────────────────────────────────

  static CodeFramework _framework(String t, CodeLanguage l) {
    bool has(String p) => t.contains(p);

    switch (l) {
      case CodeLanguage.dart:
        if (has('StatelessWidget') || has('StatefulWidget') || has('Widget build') ||
            has('MaterialApp') || has('BuildContext')) { return CodeFramework.flutter; }
      case CodeLanguage.javascript:
      case CodeLanguage.typescript:
        if (has('getServerSideProps') || has('getStaticProps') || has('next/router') || has('NextPage')) {
          return CodeFramework.nextjs;
        }
        if (has('React') || has('useState') || has('useEffect') || has('props.') || has('JSX')) {
          return CodeFramework.react;
        }
        if (has('defineComponent') || has('v-model') || has('<template>') || has('script setup')) {
          return CodeFramework.vue;
        }
        if (has('@Component') || has('@NgModule') || has('@Injectable')) return CodeFramework.angular;
        if (has('express()') || has('app.get(') || has('app.post(') || has('app.use(')) return CodeFramework.express;
      case CodeLanguage.python:
        if (has('from django') || has('django.db') || has('models.Model')) return CodeFramework.django;
        if (has('Flask(__name__') || has('@app.route') || has('from flask')) return CodeFramework.flask;
      case CodeLanguage.java:
        if (has('@SpringBootApplication') || has('@Controller') || has('@RestController') || has('@Service')) {
          return CodeFramework.spring;
        }
      default:
        break;
    }
    return CodeFramework.none;
  }
}

// ─── CodeHighlighter ──────────────────────────────────────────────────────────
// VS Code Dark+ colour palette

class CodeHighlighter {
  static const _kw   = Color(0xFF569CD6); // blue — keywords/declarators
  static const _sp   = Color(0xFFC586C0); // purple — control flow
  static const _str  = Color(0xFFCE9178); // salmon — strings
  static const _cmt  = Color(0xFF6A9955); // green — comments
  static const _num  = Color(0xFFB5CEA8); // light green — numbers
  static const _typ  = Color(0xFF4EC9B0); // teal — type names
  static const _fn   = Color(0xFFDCDCAA); // yellow — function calls
  static const _def  = Color(0xFFD4D4D4); // default text
  static const _punc = Color(0xFF808080); // punctuation
  static const _attr = Color(0xFF9CDCFE); // light blue — attributes/keys
  static const _tag  = Color(0xFF569CD6); // HTML tags (same as keyword blue)

  static const _ff   = 'Consolas';
  static const _fs   = 11.0;

  // ── Public entry point ─────────────────────────────────────────────────────

  static List<TextSpan> highlight(String text, CodeLanguage language, {int maxLines = 14}) {
    final src = maxLines > 0 ? text.split('\n').take(maxLines).join('\n') : text;
    return switch (language) {
      CodeLanguage.html  => _html(src),
      CodeLanguage.css   => _css(src),
      CodeLanguage.json  => _json(src),
      CodeLanguage.sql   => _sql(src),
      CodeLanguage.yaml  => _yaml(src),
      CodeLanguage.shell => _shell(src),
      _                  => _generic(src, language),
    };
  }

  // ── Generic tokenizer engine ───────────────────────────────────────────────

  static List<TextSpan> _run(String src, List<(RegExp, Color)> rules) {
    final spans = <TextSpan>[];
    int pos = 0;
    while (pos < src.length) {
      bool matched = false;
      for (final (rx, color) in rules) {
        final m = rx.matchAsPrefix(src, pos);
        if (m != null && m.end > pos) {
          spans.add(TextSpan(text: m.group(0)!, style: _ts(color)));
          pos = m.end;
          matched = true;
          break;
        }
      }
      if (!matched) {
        spans.add(TextSpan(text: src[pos], style: _ts(_def)));
        pos++;
      }
    }
    return spans;
  }

  static TextStyle _ts(Color c) =>
      TextStyle(color: c, fontFamily: _ff, fontSize: _fs, height: 1.6);

  // ── Generic (covers Dart, Python, JS/TS, Java, C++, Go, Rust, Kotlin, Swift)

  static List<TextSpan> _generic(String src, CodeLanguage lang) {
    final sps = _specials(lang);
    final kws = _keywords(lang);
    final tys = _types(lang);
    final isPython = lang == CodeLanguage.python;
    final useHash  = isPython;

    final rules = <(RegExp, Color)>[
      // Comments
      (RegExp(r'\/\*[\s\S]*?\*\/'), _cmt),
      if (!useHash) (RegExp(r'\/\/[^\n]*'), _cmt),
      if (useHash)  (RegExp(r'#[^\n]*'), _cmt),
      // Triple-quoted strings
      if (isPython || lang == CodeLanguage.dart) ...[
        (RegExp(r'"""[\s\S]*?"""'), _str),
        (RegExp(r"'''[\s\S]*?'''"), _str),
      ],
      // Strings
      (RegExp(r'`(?:[^`\\]|\\.)*`'), _str),
      (RegExp(r'"(?:[^"\\]|\\.)*"'), _str),
      (RegExp(r"'(?:[^'\\]|\\.)*'"), _str),
      // Numbers
      (RegExp(r'\b0x[0-9a-fA-F]+\b'), _num),
      (RegExp(r'\b\d+\.?\d*([eE][+-]?\d+)?\b'), _num),
      // Control keywords (purple)
      if (sps.isNotEmpty) (RegExp('\\b(${sps.join('|')})\\b'), _sp),
      // Declaration keywords (blue)
      if (kws.isNotEmpty) (RegExp('\\b(${kws.join('|')})\\b'), _kw),
      // Built-in types (teal)
      if (tys.isNotEmpty) (RegExp('\\b(${tys.join('|')})\\b'), _typ),
      // PascalCase identifiers → types
      (RegExp(r'\b[A-Z][A-Za-z0-9_]*\b'), _typ),
      // Function/method calls
      (RegExp(r'\b[a-z_][a-zA-Z0-9_]*(?=\s*\()'), _fn),
      // Punctuation
      (RegExp(r'[{}()\[\];,.]'), _punc),
      // Operators
      (RegExp(r'[+\-*/%=<>!&|^~?:@]'), _def),
      // Whitespace
      (RegExp(r'[ \t\r\n]+'), _def),
    ];

    return _run(src, rules);
  }

  // ── HTML ───────────────────────────────────────────────────────────────────

  static List<TextSpan> _html(String src) {
    final rules = <(RegExp, Color)>[
      (RegExp(r'<!--[\s\S]*?-->'), _cmt),
      (RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), _typ),
      (RegExp(r'<\/[a-zA-Z][a-zA-Z0-9-]*\s*>'), _tag),
      (RegExp(r'<[a-zA-Z][a-zA-Z0-9-]*'), _tag),
      (RegExp(r'\/>|>'), _punc),
      (RegExp(r'[a-zA-Z][\w-]*(?=\s*=)'), _attr),
      (RegExp(r'"[^"]*"'), _str),
      (RegExp(r"'[^']*'"), _str),
      (RegExp(r'='), _punc),
      (RegExp(r'\s+'), _def),
      (RegExp('[^<>=\\s"\' ]+'), _def),
    ];
    return _run(src, rules);
  }

  // ── CSS ────────────────────────────────────────────────────────────────────

  static List<TextSpan> _css(String src) {
    const cssProps = [
      'color', 'background', 'background-color', 'font-size', 'font-family',
      'font-weight', 'margin', 'padding', 'border', 'border-radius', 'width',
      'height', 'display', 'flex', 'flex-direction', 'justify-content',
      'align-items', 'position', 'top', 'left', 'right', 'bottom', 'opacity',
      'overflow', 'cursor', 'text-align', 'line-height', 'letter-spacing',
      'transition', 'transform', 'animation', 'box-shadow', 'z-index',
      'content', 'visibility', 'pointer-events', 'outline', 'gap',
    ];
    final propPat = RegExp('\\b(${cssProps.join('|')})(?=\\s*:)');

    final rules = <(RegExp, Color)>[
      (RegExp(r'\/\*[\s\S]*?\*\/'), _cmt),
      (RegExp(r'@[a-zA-Z-]+'), _sp),
      (RegExp(r'"[^"]*"'), _str),
      (RegExp(r"'[^']*'"), _str),
      (RegExp(r'#[0-9a-fA-F]{3,8}\b'), _num),
      (RegExp(r'-?\d+\.?\d*(px|em|rem|vh|vw|%|s|ms|deg)?\b'), _num),
      (propPat, _attr),
      (RegExp(r':[a-zA-Z-]+(?=\s*[{(,])'), _sp),
      (RegExp(r'\b(none|auto|inherit|initial|unset|normal|bold|flex|grid|block|inline|relative|absolute|fixed|sticky)\b'), _kw),
      (RegExp(r'[{}:;,]'), _punc),
      (RegExp(r'\s+'), _def),
    ];
    return _run(src, rules);
  }

  // ── JSON ───────────────────────────────────────────────────────────────────

  static List<TextSpan> _json(String src) {
    final rules = <(RegExp, Color)>[
      (RegExp(r'"(?:[^"\\]|\\.)*"(?=\s*:)'), _attr),
      (RegExp(r'"(?:[^"\\]|\\.)*"'), _str),
      (RegExp(r'\b(true|false|null)\b'), _kw),
      (RegExp(r'-?\d+\.?\d*([eE][+-]?\d+)?\b'), _num),
      (RegExp(r'[{}\[\]:,]'), _punc),
      (RegExp(r'\s+'), _def),
    ];
    return _run(src, rules);
  }

  // ── SQL ────────────────────────────────────────────────────────────────────

  static List<TextSpan> _sql(String src) {
    const kws = [
      'SELECT', 'FROM', 'WHERE', 'INSERT', 'INTO', 'UPDATE', 'SET', 'DELETE',
      'CREATE', 'TABLE', 'DROP', 'ALTER', 'ADD', 'COLUMN', 'PRIMARY', 'KEY',
      'FOREIGN', 'REFERENCES', 'INDEX', 'VIEW', 'DATABASE', 'ORDER', 'BY',
      'GROUP', 'HAVING', 'JOIN', 'LEFT', 'RIGHT', 'INNER', 'OUTER', 'FULL',
      'CROSS', 'ON', 'AS', 'AND', 'OR', 'NOT', 'IN', 'EXISTS', 'BETWEEN',
      'LIKE', 'IS', 'NULL', 'DISTINCT', 'LIMIT', 'OFFSET', 'UNION', 'ALL',
      'COUNT', 'SUM', 'AVG', 'MIN', 'MAX', 'CASE', 'WHEN', 'THEN', 'ELSE',
      'END', 'VALUES', 'DEFAULT', 'CONSTRAINT', 'UNIQUE', 'AUTO_INCREMENT',
      'INT', 'VARCHAR', 'TEXT', 'BOOLEAN', 'DATE', 'TIMESTAMP', 'DECIMAL',
      'FLOAT', 'CHAR', 'SERIAL', 'COMMIT', 'ROLLBACK', 'BEGIN', 'TRANSACTION',
    ];
    final rules = <(RegExp, Color)>[
      (RegExp(r'--[^\n]*'), _cmt),
      (RegExp(r'\/\*[\s\S]*?\*\/'), _cmt),
      (RegExp(r"'(?:[^'\\]|\\.)*'"), _str),
      (RegExp(r'"(?:[^"\\]|\\.)*"'), _str),
      (RegExp('\\b(${kws.join('|')})\\b', caseSensitive: false), _kw),
      (RegExp(r'\b\d+\.?\d*\b'), _num),
      (RegExp(r'[();,.*=<>!]'), _punc),
      (RegExp(r'\b[A-Z_][A-Z0-9_]*\b'), _typ),
      (RegExp(r'\s+'), _def),
    ];
    return _run(src, rules);
  }

  // ── YAML ───────────────────────────────────────────────────────────────────

  static List<TextSpan> _yaml(String src) {
    final rules = <(RegExp, Color)>[
      (RegExp(r'#[^\n]*'), _cmt),
      (RegExp(r'---'), _sp),
      (RegExp(r'[\w][\w-]*(?=\s*:)'), _attr),
      (RegExp(r'"(?:[^"\\]|\\.)*"'), _str),
      (RegExp(r"'(?:[^'\\]|\\.)*'"), _str),
      (RegExp(r'\b(true|false|null|yes|no|on|off)\b', caseSensitive: false), _kw),
      (RegExp(r'\b\d+\.?\d*\b'), _num),
      (RegExp(r'-(?=\s)'), _sp),
      (RegExp(r'[:{},\[\]]'), _punc),
      (RegExp(r'\s+'), _def),
    ];
    return _run(src, rules);
  }

  // ── Shell ──────────────────────────────────────────────────────────────────

  static List<TextSpan> _shell(String src) {
    final rules = <(RegExp, Color)>[
      (RegExp(r'#![^\n]*'), _sp),
      (RegExp(r'#[^\n]*'), _cmt),
      (RegExp(r'"(?:[^"\\]|\\.)*"'), _str),
      (RegExp(r"'[^']*'"), _str),
      (RegExp(r'\$\{?[A-Za-z_][A-Za-z0-9_]*\}?'), _attr),
      (RegExp(r'\$\([^)]*\)'), _typ),
      (RegExp(r'\b(if|then|else|elif|fi|for|while|do|done|case|esac|in|return|exit|export|local|function)\b'), _kw),
      (RegExp(r'\b(echo|cd|ls|grep|awk|sed|cat|chmod|mkdir|rm|cp|mv|find|sort|curl|wget|git|npm|yarn|pip)\b'), _fn),
      (RegExp(r'\b\d+\b'), _num),
      (RegExp(r'[|&;><!]'), _punc),
      (RegExp(r'\s+'), _def),
    ];
    return _run(src, rules);
  }

  // ── Keyword tables ─────────────────────────────────────────────────────────

  static List<String> _specials(CodeLanguage l) => switch (l) {
    CodeLanguage.dart => [
      'return', 'import', 'export', 'if', 'else', 'for', 'while', 'switch',
      'case', 'break', 'continue', 'try', 'catch', 'finally', 'throw',
      'async', 'await', 'yield', 'new',
    ],
    CodeLanguage.python => [
      'return', 'import', 'from', 'if', 'elif', 'else', 'for', 'while',
      'with', 'as', 'try', 'except', 'finally', 'raise', 'yield', 'pass',
      'break', 'continue', 'lambda', 'del', 'global', 'nonlocal', 'assert',
    ],
    CodeLanguage.javascript || CodeLanguage.typescript => [
      'return', 'import', 'export', 'if', 'else', 'for', 'while', 'switch',
      'case', 'break', 'continue', 'try', 'catch', 'finally', 'throw',
      'async', 'await', 'yield', 'new', 'delete', 'typeof', 'instanceof',
      'in', 'of', 'from',
    ],
    CodeLanguage.java => [
      'return', 'if', 'else', 'for', 'while', 'do', 'switch', 'case',
      'break', 'continue', 'try', 'catch', 'finally', 'throw', 'throws',
      'new', 'instanceof', 'import', 'package',
    ],
    CodeLanguage.cpp => [
      'return', 'if', 'else', 'for', 'while', 'do', 'switch', 'case',
      'break', 'continue', 'try', 'catch', 'throw', 'new', 'delete',
      'namespace', 'using',
    ],
    CodeLanguage.go => [
      'return', 'if', 'else', 'for', 'switch', 'case', 'break', 'continue',
      'defer', 'go', 'select', 'goto', 'fallthrough', 'import', 'package',
    ],
    CodeLanguage.rust => [
      'return', 'if', 'else', 'for', 'while', 'loop', 'match', 'break',
      'continue', 'use', 'mod', 'pub', 'crate', 'extern', 'unsafe',
      'async', 'await', 'move',
    ],
    CodeLanguage.kotlin => [
      'return', 'if', 'else', 'for', 'while', 'when', 'break', 'continue',
      'try', 'catch', 'finally', 'throw', 'import', 'package', 'is', 'as', 'in',
    ],
    CodeLanguage.swift => [
      'return', 'if', 'else', 'for', 'while', 'switch', 'case', 'break',
      'continue', 'try', 'catch', 'throw', 'guard', 'defer', 'import', 'in',
    ],
    _ => [],
  };

  static List<String> _keywords(CodeLanguage l) => switch (l) {
    CodeLanguage.dart => [
      'class', 'abstract', 'extends', 'implements', 'mixin', 'with', 'enum',
      'typedef', 'void', 'const', 'final', 'var', 'late', 'static', 'override',
      'required', 'get', 'set', 'super', 'this', 'null', 'true', 'false',
    ],
    CodeLanguage.python => [
      'class', 'def', 'None', 'True', 'False', 'and', 'or', 'not', 'in',
      'is', 'self', 'cls', 'super',
    ],
    CodeLanguage.javascript => [
      'const', 'let', 'var', 'function', 'class', 'extends', 'null',
      'undefined', 'true', 'false', 'this', 'super', 'static', 'get', 'set',
    ],
    CodeLanguage.typescript => [
      'const', 'let', 'var', 'function', 'class', 'interface', 'type', 'enum',
      'extends', 'implements', 'abstract', 'readonly', 'null', 'undefined',
      'true', 'false', 'this', 'super', 'static', 'get', 'set', 'declare',
      'namespace', 'override',
    ],
    CodeLanguage.java => [
      'class', 'interface', 'extends', 'implements', 'abstract', 'static',
      'final', 'public', 'private', 'protected', 'this', 'super', 'null',
      'true', 'false', 'synchronized', 'volatile', 'enum',
    ],
    CodeLanguage.cpp => [
      'class', 'struct', 'public', 'private', 'protected', 'virtual',
      'override', 'const', 'static', 'inline', 'auto', 'this', 'nullptr',
      'true', 'false', 'template', 'typename', 'typedef', 'enum', 'friend',
      'operator', 'explicit',
    ],
    CodeLanguage.go => [
      'func', 'var', 'const', 'type', 'struct', 'interface', 'map', 'chan',
      'true', 'false', 'nil', 'make', 'len', 'cap', 'append', 'copy',
      'close', 'delete', 'panic', 'recover',
    ],
    CodeLanguage.rust => [
      'fn', 'let', 'mut', 'const', 'static', 'struct', 'enum', 'impl',
      'trait', 'type', 'self', 'Self', 'true', 'false', 'None', 'Some',
      'Ok', 'Err',
    ],
    CodeLanguage.kotlin => [
      'class', 'object', 'interface', 'fun', 'val', 'var', 'enum', 'sealed',
      'abstract', 'override', 'open', 'final', 'inner', 'data', 'companion',
      'null', 'true', 'false', 'this', 'super', 'it', 'by', 'constructor',
    ],
    CodeLanguage.swift => [
      'class', 'struct', 'enum', 'protocol', 'extension', 'func', 'var',
      'let', 'override', 'final', 'public', 'private', 'internal', 'static',
      'init', 'deinit', 'nil', 'true', 'false', 'self', 'Self', 'super',
      'mutating', 'lazy', 'optional', 'required',
    ],
    _ => [],
  };

  static List<String> _types(CodeLanguage l) => switch (l) {
    CodeLanguage.dart => [
      'dynamic', 'bool', 'int', 'double', 'String', 'List', 'Map', 'Set',
      'Future', 'Stream', 'Object', 'num',
    ],
    CodeLanguage.python => [
      'int', 'str', 'float', 'bool', 'list', 'dict', 'set', 'tuple', 'bytes',
      'type', 'object', 'Exception',
    ],
    CodeLanguage.typescript => [
      'string', 'number', 'boolean', 'any', 'void', 'never', 'unknown',
      'object', 'Array', 'Promise', 'Record', 'Partial', 'Required',
      'Readonly', 'Pick', 'Omit',
    ],
    CodeLanguage.java => [
      'void', 'int', 'long', 'double', 'float', 'boolean', 'char', 'byte',
      'short', 'String', 'Object', 'Integer', 'Long', 'Double', 'Boolean',
    ],
    CodeLanguage.cpp => [
      'void', 'int', 'long', 'double', 'float', 'bool', 'char', 'auto',
      'string', 'vector', 'map', 'set',
    ],
    CodeLanguage.rust => [
      'bool', 'i8', 'i16', 'i32', 'i64', 'i128', 'isize',
      'u8', 'u16', 'u32', 'u64', 'u128', 'usize', 'f32', 'f64',
      'str', 'String', 'Vec', 'Option', 'Result', 'Box',
    ],
    _ => [],
  };
}
