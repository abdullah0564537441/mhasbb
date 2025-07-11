// lib/screens/calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = '';
  String _output = '0';
  String _operator = ''; // لتخزين آخر عملية حسابية (+, -, *, /)
  double _firstOperand = 0.0; // لتخزين المعامل الأول في عمليات النسبة المئوية

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        _input = '';
        _output = '0';
        _operator = '';
        _firstOperand = 0.0;
      } else if (buttonText == '⌫') { // Backspace
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
        if (_input.isEmpty) {
          _output = '0'; // إذا أصبح الإدخال فارغاً، أعد الناتج إلى 0
        }
      } else if (buttonText == '=') {
        _calculateResult();
      } else if (['+', '-', '×', '÷'].contains(buttonText)) {
        // إذا كان هناك مدخل بالفعل، احسب الناتج قبل تطبيق العملية الجديدة
        if (_input.isNotEmpty && !['+', '-', '×', '÷'].contains(_input[_input.length - 1])) {
          _calculateResult(); // احسب الناتج الحالي
        }
        // تخزين المعامل الأول والعملية
        if (_output != '0' && _output != 'خطأ') { // استخدم الناتج الحالي كمعامل أول
          _firstOperand = double.tryParse(_output) ?? 0.0;
        } else if (_input.isNotEmpty && _output == '0') { // إذا لم يكن هناك ناتج لكن يوجد مدخل
            try {
              Parser p = Parser();
              Expression exp = p.parse(_input.replaceAll('×', '*').replaceAll('÷', '/'));
              ContextModel cm = ContextModel();
              _firstOperand = exp.evaluate(EvaluationType.REAL, cm);
            } catch (e) {
              _firstOperand = 0.0; // في حالة وجود خطأ
            }
        } else {
          _firstOperand = 0.0; // إذا لا يوجد مدخل أو ناتج، اجعله 0
        }

        _operator = buttonText;
        _input += buttonText; // أضف العملية إلى الإدخال
      } else if (buttonText == '%') {
        _handlePercentage();
      } else {
        _input += buttonText;
      }
    });
  }

  void _calculateResult() {
    try {
      String finalInput = _input.replaceAll('×', '*').replaceAll('÷', '/');
      
      // تأكد من أن التعبير لا ينتهي بعامل تشغيل
      if (finalInput.isNotEmpty && ['*', '/', '+', '-'].contains(finalInput[finalInput.length - 1])) {
        finalInput = finalInput.substring(0, finalInput.length - 1);
      }

      Parser p = Parser();
      Expression exp = p.parse(finalInput);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);

      _output = _formatResult(result);
      _input = _output; // اجعل الناتج هو المدخل للعملية التالية
      _operator = ''; // إعادة تعيين العملية
      _firstOperand = result; // تحديث المعامل الأول للعمليات اللاحقة
    } catch (e) {
      _output = 'خطأ';
      print('Calculator Error: $e');
      _input = ''; // مسح الإدخال عند الخطأ
    }
  }

  void _handlePercentage() {
    if (_input.isEmpty || _output == 'خطأ') return;

    try {
      // ابحث عن الرقم الأخير قبل علامة النسبة المئوية
      RegExp numRegExp = RegExp(r'(\d+\.?\d*)$');
      Match? match = numRegExp.firstMatch(_input);

      if (match != null) {
        double value = double.parse(match.group(1)!);
        double percentageValue = value / 100.0;

        // إزالة الرقم الأصلي وعلامة النسبة المئوية من _input مؤقتًا للتحليل
        String tempInputWithoutPercentage = _input.substring(0, match.start);

        double calculatedPercentageAmount = 0.0;

        if (_operator.isNotEmpty && _firstOperand != 0.0) {
          if (_operator == '+' || _operator == '-') {
            calculatedPercentageAmount = _firstOperand * percentageValue;
          } else if (_operator == '×' || _operator == '÷') {
            calculatedPercentageAmount = percentageValue; // للضرب والقسمة، النسبة المئوية نفسها هي القيمة
          }

          // بناء التعبير النهائي لإرساله إلى math_expressions
          String expressionToEvaluate;
          if (_operator == '+' || _operator == '-') {
            // مثلا: 100 + (100 * 0.15)
            // أو: 500 - (500 * 0.20)
            expressionToEvaluate = '${_firstOperand.toString()} $_operator ${_formatResult(calculatedPercentageAmount)}';
          } else {
            // مثلا: 200 * 0.50
            expressionToEvaluate = '${_firstOperand.toString()} $_operator ${_formatResult(calculatedPercentageAmount)}';
          }

          Parser p = Parser();
          Expression exp = p.parse(expressionToEvaluate.replaceAll('×', '*').replaceAll('÷', '/'));
          ContextModel cm = ContextModel();
          double finalResult = exp.evaluate(EvaluationType.REAL, cm);

          _output = _formatResult(finalResult);
          _input = _output; // اجعل الناتج هو المدخل للعملية التالية
          _operator = '';
          _firstOperand = finalResult;
        } else {
          // إذا لم يكن هناك معامل سابق (مثل 25% فقط)، فقط اعرض القيمة المئوية
          _output = _formatResult(percentageValue);
          _input = _output;
        }
      }
    } catch (e) {
      _output = 'خطأ';
      print('Percentage Error: $e');
      _input = '';
    }
  }

  String _formatResult(double result) {
    if (result == result.toInt().toDouble()) {
      return result.toInt().toString(); // إذا كان عدد صحيح، لا تظهر الفاصلة
    }
    return result.toStringAsFixed(5).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), ''); // لإزالة الأصفار الزائدة
  }


  Widget _buildButton(String buttonText, {Color color = Colors.black54, Color textColor = Colors.white}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: () => _onButtonPressed(buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            minimumSize: const Size(60, 60),
          ),
          child: Text(buttonText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الآلة الحاسبة'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _input.isEmpty ? '0' : _input,
                    style: const TextStyle(fontSize: 32, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _output,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Row(children: [
                  _buildButton('C', color: Colors.redAccent), // زر C
                  _buildButton('⌫', color: Colors.blueGrey), // ⭐⭐ زر الحذف هنا الآن
                  _buildButton('%', color: Colors.blueGrey),
                  _buildButton('÷', color: Colors.orangeAccent),
                ]),
                Row(children: [
                  _buildButton('7'),
                  _buildButton('8'),
                  _buildButton('9'),
                  _buildButton('×', color: Colors.orangeAccent),
                ]),
                Row(children: [
                  _buildButton('4'),
                  _buildButton('5'),
                  _buildButton('6'),
                  _buildButton('-', color: Colors.orangeAccent),
                ]),
                Row(children: [
                  _buildButton('1'),
                  _buildButton('2'),
                  _buildButton('3'),
                  _buildButton('+', color: Colors.orangeAccent),
                ]),
                Row(children: [
                  _buildButton('00', color: Colors.black45),
                  _buildButton('0'),
                  _buildButton('.', color: Colors.black45),
                  _buildButton('=', color: Colors.green), // ⭐⭐ زر = هنا الآن
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
