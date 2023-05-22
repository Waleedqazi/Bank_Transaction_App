import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(BankTransactionsApp());
}

class BankTransactionsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank Transactions',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TransactionListScreen(),
    );
  }
}

class Transaction {
  final String id;
  final DateTime date;
  final double amount;
  final String currency;
  final String type;

  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.currency,
    required this.type,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      date: DateTime.parse(json['date']),
      amount: (json['amount'] is num)
          ? json['amount'].toDouble()
          : double.parse(json['amount']),
      currency: json['currency'],
      type: json['type'],
    );
  }

  String get formattedDate {
    return '${date.day}-${date.month}-${date.year}';
  }
}

class TransactionListScreen extends StatefulWidget {
  @override
  _TransactionListScreenState createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  List<Transaction> transactions = [];
  List<Transaction> filteredTransactions = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final Uri url = Uri.parse(
          'https://64677d7f2ea3cae8dc3091e7.mockapi.io/api/v1/transactions');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        List<Transaction> fetchedTransactions = [];
        for (var jsonTransaction in jsonBody) {
          fetchedTransactions.add(Transaction.fromJson(jsonTransaction));
        }
        setState(() {
          transactions = fetchedTransactions;
          filteredTransactions = fetchedTransactions;
          isLoading = false;
        });
      } else {
        print('Failed to fetch transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while fetching transactions: $e');
    }
  }

  void searchTransactions(String query) {
    List<Transaction> matchedTransactions = transactions.where((transaction) {
      String formattedQuery = query.toLowerCase();
      String formattedDate = transaction.formattedDate.toLowerCase();
      String formattedAmount = transaction.amount.toString().toLowerCase();
      String formattedCurrency = transaction.currency.toLowerCase();
      String formattedType = transaction.type.toLowerCase();

      return formattedDate.contains(formattedQuery) ||
          formattedAmount.contains(formattedQuery) ||
          formattedCurrency.contains(formattedQuery) ||
          formattedType.contains(formattedQuery);
    }).toList();

    setState(() {
      filteredTransactions = matchedTransactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bank Transactions'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          searchTransactions('');
                        },
                      ),
                    ),
                    onChanged: searchTransactions,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return ListTile(
                        title: Text(transaction.formattedDate),
                        subtitle: Text(
                            '${transaction.amount} ${transaction.currency} - ${transaction.type}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionDetailsScreen(
                                transaction: transaction,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class TransactionDetailsScreen extends StatelessWidget {
  final Transaction transaction;

  TransactionDetailsScreen({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Details'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Date'),
            subtitle: Text(transaction.formattedDate),
          ),
          ListTile(
            title: Text('Amount'),
            subtitle: Text('${transaction.amount} ${transaction.currency}'),
          ),
          ListTile(
            title: Text('Type'),
            subtitle: Text(transaction.type),
          ),
        ],
      ),
    );
  }
}
