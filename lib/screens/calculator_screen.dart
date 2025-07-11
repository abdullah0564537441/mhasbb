// lib/screens/calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart'; // ستحتاج لإضافة هذه الحزمة

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = '';
  String _output = '0';

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        _input = '';
        _output = '0';
      } else if (buttonText == '=') {
        try {
          Parser p = Parser();
          Expression exp = p.parse(_input.replaceAll('×', '*').replaceAll('÷', '/'));
          ContextModel cm = ContextModel();
          _output = exp.evaluate(EvaluationType.REAL, cm).toString();
          // إذا كان الناتج ينتهي بـ ".0"، قم بإزالته
          if (_output.endsWith('.0')) {
            _output = _output.substring(0, _output.length - 2);
          }
        } catch (e) {
          _output = 'خطأ';
        }
      } else if (buttonText == '⌫') { // Backspace
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
        if (_input.isEmpty) {
          _output = '0'; // If input is empty, reset output
        }
      } else {
        _input += buttonText;
      }
    });
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
            minimumSize: const Size(60, 60), // Set a minimum size
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
                  _buildButton('C', color: Colors.redAccent),
                  _buildButton('⌫', color: Colors.blueGrey),
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
                  _buildButton('=', color: Colors.green),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
