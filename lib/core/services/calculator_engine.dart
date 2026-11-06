import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class CalculatorEngine extends ChangeNotifier {
  String _display = '0';
  String _history = '';
  double _memory = 0.0;
  bool _isRadian = true;
  bool _shouldResetDisplay = false;

  String get display => _display;
  String get history => _history;
  double get memory => _memory;
  bool get isRadian => _isRadian;
  bool get hasMemory => _memory != 0.0;

  void setAngleMode(bool isRadian) {
    _isRadian = isRadian;
    notifyListeners();
  }

  void processKey(String key) {
    switch (key) {
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        _inputDigit(key);
        break;
      case '.':
        _inputDecimal();
        break;
      case '+/-':
      case '±':
        _toggleSign();
        break;
      case 'C':
        _clearAll();
        break;
      case 'CE':
        _clearEntry();
        break;
      case 'BACK':
      case '⌫':
        _backspace();
        break;
      case 'MC':
        _memory = 0.0;
        break;
      case 'MR':
        _display = _formatNumber(_memory);
        _shouldResetDisplay = true;
        break;
      case 'MS':
        _memory = double.tryParse(_display) ?? 0.0;
        break;
      case 'M+':
        _memory += double.tryParse(_display) ?? 0.0;
        break;
      case 'M-':
        _memory -= double.tryParse(_display) ?? 0.0;
        break;
      case '+':
      case '-':
      case '*':
      case '×':
      case '/':
      case '÷':
      case '%':
        _inputOperator(key);
        break;
      case '=':
        _evaluate();
        break;
      case 'pi':
      case 'π':
        _display = math.pi.toString();
        _shouldResetDisplay = true;
        break;
      case 'e':
        _display = math.e.toString();
        _shouldResetDisplay = true;
        break;
      case '(':
      case ')':
        _inputParen(key);
        break;
      case 'sin':
      case 'cos':
      case 'tan':
      case 'asin':
      case 'acos':
      case 'atan':
      case 'sinh':
      case 'cosh':
      case 'tanh':
      case 'ln':
      case 'log':
      case 'sqrt':
      case '√':
      case 'cbrt':
      case '1/x':
      case 'x^2':
      case 'x^3':
      case 'e^x':
      case '10^x':
      case 'n!':
        _applyFunction(key);
        break;
      case 'x^y':
      case '^':
        _inputOperator('^');
        break;
    }
    notifyListeners();
  }

  void _inputDigit(String d) {
    if (_shouldResetDisplay || _display == '0' || _display == 'Error') {
      _display = d;
      _shouldResetDisplay = false;
    } else {
      if (_display.length < 15) {
        _display += d;
      }
    }
  }

  void _inputDecimal() {
    if (_shouldResetDisplay || _display == 'Error') {
      _display = '0.';
      _shouldResetDisplay = false;
      return;
    }
    if (!_display.contains('.')) {
      _display += '.';
    }
  }

  void _toggleSign() {
    if (_display == '0' || _display == 'Error') return;
    if (_display.startsWith('-')) {
      _display = _display.substring(1);
    } else {
      _display = '-$_display';
    }
  }

  void _clearAll() {
    _display = '0';
    _history = '';
    _shouldResetDisplay = false;
  }

  void _clearEntry() {
    _display = '0';
    _shouldResetDisplay = false;
  }

  void _backspace() {
    if (_shouldResetDisplay || _display == 'Error') {
      _display = '0';
      _shouldResetDisplay = false;
      return;
    }
    if (_display.length > 1) {
      _display = _display.substring(0, _display.length - 1);
    } else {
      _display = '0';
    }
  }

  void _inputOperator(String op) {
    final normalizedOp = op == '×' ? '*' : (op == '÷' ? '/' : op);
    _history += ' $_display $normalizedOp';
    _shouldResetDisplay = true;
  }

  void _inputParen(String paren) {
    if (paren == '(') {
      _history += ' (';
      _shouldResetDisplay = true;
    } else {
      _history += ' $_display )';
      _shouldResetDisplay = true;
    }
  }

  void _applyFunction(String fn) {
    final val = double.tryParse(_display);
    if (val == null) return;

    double res = 0.0;
    try {
      switch (fn) {
        case 'sin':
          res = math.sin(_isRadian ? val : val * (math.pi / 180.0));
          break;
        case 'cos':
          res = math.cos(_isRadian ? val : val * (math.pi / 180.0));
          break;
        case 'tan':
          res = math.tan(_isRadian ? val : val * (math.pi / 180.0));
          break;
        case 'asin':
          res = math.asin(val);
          if (!_isRadian) res = res * (180.0 / math.pi);
          break;
        case 'acos':
          res = math.acos(val);
          if (!_isRadian) res = res * (180.0 / math.pi);
          break;
        case 'atan':
          res = math.atan(val);
          if (!_isRadian) res = res * (180.0 / math.pi);
          break;
        case 'sinh':
          res = (math.exp(val) - math.exp(-val)) / 2;
          break;
        case 'cosh':
          res = (math.exp(val) + math.exp(-val)) / 2;
          break;
        case 'tanh':
          res = (math.exp(val) - math.exp(-val)) / (math.exp(val) + math.exp(-val));
          break;
        case 'ln':
          if (val <= 0) throw Exception();
          res = math.log(val);
          break;
        case 'log':
          if (val <= 0) throw Exception();
          res = math.log(val) / math.ln10;
          break;
        case 'sqrt':
        case '√':
          if (val < 0) throw Exception();
          res = math.sqrt(val);
          break;
        case 'cbrt':
          res = val >= 0 ? math.pow(val, 1 / 3).toDouble() : -math.pow(-val, 1 / 3).toDouble();
          break;
        case '1/x':
          if (val == 0) throw Exception();
          res = 1 / val;
          break;
        case 'x^2':
          res = val * val;
          break;
        case 'x^3':
          res = val * val * val;
          break;
        case 'e^x':
          res = math.exp(val);
          break;
        case '10^x':
          res = math.pow(10, val).toDouble();
          break;
        case 'n!':
          if (val < 0 || val > 170 || val != val.floorToDouble()) throw Exception();
          res = 1.0;
          for (int i = 2; i <= val.toInt(); i++) {
            res *= i;
          }
          break;
      }
      _display = _formatNumber(res);
      _shouldResetDisplay = true;
    } catch (_) {
      _display = 'Error';
      _shouldResetDisplay = true;
    }
  }

  void _evaluate() {
    if (_history.isEmpty) return;

    final fullExpr = '$_history $_display'.trim();
    try {
      final result = _evaluateSimpleExpression(fullExpr);
      _history = '';
      _display = _formatNumber(result);
      _shouldResetDisplay = true;
    } catch (e) {
      _display = 'Error';
      _history = '';
      _shouldResetDisplay = true;
    }
  }

  double _evaluateSimpleExpression(String expr) {
    // Tokenize
    final tokens = expr.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return 0.0;

    // Process left to right for standard exam calculator operations
    double current = double.tryParse(tokens[0]) ?? 0.0;
    for (int i = 1; i < tokens.length; i += 2) {
      if (i + 1 >= tokens.length) break;
      final op = tokens[i];
      final nextVal = double.tryParse(tokens[i + 1]) ?? 0.0;

      switch (op) {
        case '+':
          current += nextVal;
          break;
        case '-':
          current -= nextVal;
          break;
        case '*':
          current *= nextVal;
          break;
        case '/':
          if (nextVal == 0) throw Exception('Divide by zero');
          current /= nextVal;
          break;
        case '%':
          current %= nextVal;
          break;
        case '^':
          current = math.pow(current, nextVal).toDouble();
          break;
      }
    }
    return current;
  }

  String _formatNumber(double n) {
    if (n.isNaN || n.isInfinite) return 'Error';
    if (n == n.roundToDouble()) {
      return n.toInt().toString();
    }
    final str = n.toStringAsPrecision(8);
    return double.parse(str).toString();
  }
}

