// lib/screens/account_statement_screen.dart
import 'package:flutter/material.dart';

class AccountStatementScreen extends StatelessWidget {
  const AccountStatementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // بيانات وهمية للحركات المالية
    final List<Map<String, dynamic>> transactions = [
      {'date': '2024-07-01', 'description': 'فاتورة مبيعات #1001', 'amount': 150.0, 'type': 'credit'},
      {'date': '2024-07-02', 'description': 'دفعة من العميل أ', 'amount': 200.0, 'type': 'debit'},
      {'date': '2024-07-03', 'description': 'فاتورة مشتريات #500', 'amount': -75.0, 'type': 'debit'},
      {'date': '2024-07-04', 'description': 'سند قبض #001', 'amount': 120.0, 'type': 'credit'},
      {'date': '2024-07-05', 'description': 'فاتورة مبيعات #1002', 'amount': 300.0, 'type': 'credit'},
      {'date': '2024-07-06', 'description': 'فاتورة مشتريات #501', 'amount': -110.0, 'type': 'debit'},
      {'date': '2024-07-07', 'description': 'سند صرف #002', 'amount': -50.0, 'type': 'debit'},
      {'date': '2024-07-08', 'description': 'دفعة من العميل ب', 'amount': 250.0, 'type': 'debit'},
    ];

    double currentBalance = 0.0;
    for (var t in transactions) {
      if (t['type'] == 'credit') {
        currentBalance += t['amount'];
      } else {
        currentBalance += t['amount']; // لأن الأرقام السالبة هي خصم
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف الحسابات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الرصيد الحالي:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currentBalance.toStringAsFixed(2)} ر.س', // تنسيق الرقم ليكون من منزلتين عشريتين
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: currentBalance >= 0 ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(
                      transaction['type'] == 'credit' ? Icons.add_circle : Icons.remove_circle,
                      color: transaction['type'] == 'credit' ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      transaction['description'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(transaction['date']),
                    trailing: Text(
                      '${transaction['amount'].toStringAsFixed(2)} ر.س',
                      style: TextStyle(
                        color: transaction['amount'] >= 0 ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
