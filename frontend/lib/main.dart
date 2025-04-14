// main.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final List<Expense> _expenses = [];
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddExpenseOptions(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildExpensesList();
      case 1:
        return _buildStatistics();
      case 2:
        return _buildSettings();
      default:
        return _buildExpensesList();
    }
  }

  Widget _buildExpensesList() {
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No expenses yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add an expense to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _showAddExpenseOptions(context);
              },
              child: const Text('Add Expense'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(_getCategoryIcon(expense.category)),
            ),
            title: Text(expense.title),
            subtitle: Text(expense.category),
            trailing: Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onTap: () {
              _showExpenseDetails(expense);
            },
          ),
        );
      },
    );
  }

  Widget _buildStatistics() {
    double totalExpenses = _expenses.fold(0, (sum, expense) => sum + expense.amount);
    
    // Create a map of category totals
    Map<String, double> categoryTotals = {};
    for (var expense in _expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Expenses',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${totalExpenses.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Expenses by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: categoryTotals.isEmpty
                ? const Center(child: Text('No data to display'))
                : ListView.builder(
                    itemCount: categoryTotals.length,
                    itemBuilder: (context, index) {
                      String category = categoryTotals.keys.elementAt(index);
                      double amount = categoryTotals[category]!;
                      double percentage = amount / totalExpenses * 100;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(_getCategoryIcon(category), size: 20),
                                    const SizedBox(width: 8),
                                    Text(category),
                                  ],
                                ),
                                Text('\$${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[300],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildSettingsCard(
            'Data Sources',
            [
              SettingsItem(
                'Bank Messages',
                'Link your bank SMS messages',
                Icons.sms,
                () => _requestSmsPermission(),
              ),
              SettingsItem(
                'OCR Settings',
                'Configure bill scanning preferences',
                Icons.document_scanner,
                () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            'Account',
            [
              SettingsItem(
                'Export Data',
                'Export your expense data',
                Icons.download,
                () {},
              ),
              SettingsItem(
                'Categories',
                'Manage expense categories',
                Icons.category,
                () => _showCategoriesManagement(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            'Appearance',
            [
              SettingsItem(
                'Theme',
                'Change app theme',
                Icons.color_lens,
                () {},
              ),
              SettingsItem(
                'Currency',
                'Set your preferred currency',
                Icons.attach_money,
                () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, List<SettingsItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _buildSettingsItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(SettingsItem item) {
    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: item.onTap,
    );
  }

  void _showAddExpenseOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Expense',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildAddExpenseOption(
                context,
                'Manual Entry',
                Icons.edit,
                () {
                  Navigator.pop(context);
                  _showManualEntryForm();
                },
              ),
              const SizedBox(height: 16),
              _buildAddExpenseOption(
                context,
                'Scan Bill',
                Icons.document_scanner,
                () {
                  Navigator.pop(context);
                  _scanBill();
                },
              ),
              const SizedBox(height: 16),
              _buildAddExpenseOption(
                context,
                'From Bank Messages',
                Icons.sms,
                () {
                  Navigator.pop(context);
                  _showBankMessages();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddExpenseOption(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  void _showManualEntryForm() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Food';
    final dateController = TextEditingController(
      text: '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
    );
    String? notes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Expense',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'Food',
                      'Transportation',
                      'Entertainment',
                      'Shopping',
                      'Bills',
                      'Health',
                      'Other',
                    ].map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Row(
                          children: [
                            Icon(_getCategoryIcon(category)),
                            const SizedBox(width: 8),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          dateController.text =
                              '${pickedDate.month}/${pickedDate.day}/${pickedDate.year}';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      notes = value;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty &&
                            amountController.text.isNotEmpty) {
                          final newExpense = Expense(
                            title: titleController.text,
                            amount: double.parse(amountController.text),
                            category: selectedCategory,
                            date: DateTime.now(),
                            notes: notes,
                          );
                          setState(() {
                            _expenses.add(newExpense);
                          });
                          Navigator.pop(context);
                          _showSnackBar('Expense added successfully');
                        } else {
                          _showSnackBar('Please fill in all required fields');
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('Save'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _scanBill() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image == null) {
        return;
      }
      
      // Show loading indicator
      _showLoadingDialog('Scanning bill...');
      
      // In a real app, you would send the image to your OCR backend here
      // For this example, we'll simulate the OCR processing with a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);
      
      // Show the extracted information in a form for confirmation
      _showOcrResultForm({
        'title': 'Grocery Store',
        'amount': '42.75',
        'category': 'Food',
        'date': '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
      });
    } catch (e) {
      _showSnackBar('Error scanning bill: $e');
    }
  }

  void _showOcrResultForm(Map<String, String> extractedData) {
    final titleController = TextEditingController(text: extractedData['title']);
    final amountController = TextEditingController(text: extractedData['amount']);
    String selectedCategory = extractedData['category'] ?? 'Food';
    final dateController = TextEditingController(text: extractedData['date']);
    String? notes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirm Scanned Expense',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please review and edit the scanned information',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'Food',
                      'Transportation',
                      'Entertainment',
                      'Shopping',
                      'Bills',
                      'Health',
                      'Other',
                    ].map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Row(
                          children: [
                            Icon(_getCategoryIcon(category)),
                            const SizedBox(width: 8),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          dateController.text =
                              '${pickedDate.month}/${pickedDate.day}/${pickedDate.year}';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      notes = value;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text('Cancel'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.isNotEmpty &&
                                amountController.text.isNotEmpty) {
                              final newExpense = Expense(
                                title: titleController.text,
                                amount: double.parse(amountController.text),
                                category: selectedCategory,
                                date: DateTime.now(),
                                notes: notes,
                                source: 'OCR',
                              );
                              setState(() {
                                _expenses.add(newExpense);
                              });
                              Navigator.pop(context);
                              _showSnackBar('Expense added successfully');
                            } else {
                              _showSnackBar('Please fill in all required fields');
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text('Save'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _requestSmsPermission() async {
    var status = await Permission.sms.request();
    if (status.isGranted) {
      _showSnackBar('SMS permission granted');
      _showBankMessages();
    } else {
      _showSnackBar('SMS permission denied. Cannot access bank messages.');
    }
  }

  void _showBankMessages() async {
    // Simulate fetching bank messages
    await Future.delayed(const Duration(seconds: 1));
    
    // Sample bank messages
    final messages = [
      BankMessage(
        'Your account was debited with \$45.30 for Amazon.com on 04/05/2025',
        DateTime.now().subtract(const Duration(days: 2)),
        'Amazon.com',
        45.30,
      ),
      BankMessage(
        'Your account was debited with \$12.99 for Netflix Subscription on 04/01/2025',
        DateTime.now().subtract(const Duration(days: 6)),
        'Netflix',
        12.99,
      ),
      BankMessage(
        'Your account was debited with \$35.75 for Uber on 03/29/2025',
        DateTime.now().subtract(const Duration(days: 9)),
        'Uber',
        35.75,
      ),
    ];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bank Messages',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select messages to add as expenses',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(message.merchant),
                        subtitle: Text(
                          message.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${message.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${message.date.month}/${message.date.day}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showBankMessageConfirmation(message);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBankMessageConfirmation(BankMessage message) {
    final titleController = TextEditingController(text: message.merchant);
    final amountController = TextEditingController(text: message.amount.toString());
    String selectedCategory = _guessCategory(message.merchant);
    final dateController = TextEditingController(
      text: '${message.date.month}/${message.date.day}/${message.date.year}',
    );
    String? notes = message.content;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirm Bank Message Expense',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please review and edit the information',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'Food',
                      'Transportation',
                      'Entertainment',
                      'Shopping',
                      'Bills',
                      'Health',
                      'Other',
                    ].map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Row(
                          children: [
                            Icon(_getCategoryIcon(category)),
                            const SizedBox(width: 8),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: message.date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          dateController.text =
                              '${pickedDate.month}/${pickedDate.day}/${pickedDate.year}';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    controller: TextEditingController(text: notes),
                    onChanged: (value) {
                      notes = value;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text('Cancel'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.isNotEmpty &&
                                amountController.text.isNotEmpty) {
                              final newExpense = Expense(
                                title: titleController.text,
                                amount: double.parse(amountController.text),
                                category: selectedCategory,
                                date: DateTime.parse(
                                    _parseDate(dateController.text)),
                                notes: notes,
                                source: 'Bank Message',
                              );
                              setState(() {
                                _expenses.add(newExpense);
                              });
                              Navigator.pop(context);
                              _showSnackBar('Expense added successfully');
                            } else {
                              _showSnackBar('Please fill in all required fields');
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text('Save'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showExpenseDetails(Expense expense) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(_getCategoryIcon(expense.category),
                                color: Colors.grey, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              expense.category,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailItem('Date', 
                '${expense.date.month}/${expense.date.day}/${expense.date.year}'),
              if (expense.source != null)
                _buildDetailItem('Source', expense.source!),
              if (expense.notes != null && expense.notes!.isNotEmpty)
                _buildDetailItem('Notes', expense.notes!),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Show edit form here
                    },
                    child: const Text('Edit'),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _expenses.remove(expense);
                      });
                      Navigator.pop(context);
                      _showSnackBar('Expense deleted');
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showCategoriesManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final category = [
                      'Food',
                      'Transportation',
                      'Entertainment',
                      'Shopping',
                      'Bills',
                      'Health',
                      'Other',
                    ][index];
                    return ListTile(
                      leading: Icon(_getCategoryIcon(category)),
                      title: Text(category),
                      trailing: index < 6
                          ? const Icon(Icons.drag_handle)
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Add new category
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Add New Category'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills':
        return Icons.receipt;
      case 'Health':
        return Icons.medical_services;
      default:
        return Icons.category;
    }
  }

  String _guessCategory(String merchant) {
    merchant = merchant.toLowerCase();
    if (merchant.contains('amazon') ||
        merchant.contains('walmart') ||
        merchant.contains('target')) {
      return 'Shopping';
    } else if (merchant.contains('uber') ||
        merchant.contains('lyft') ||
        merchant.contains('transit')) {
      return 'Transportation';
    } else if (merchant.contains('netflix') ||
        merchant.contains('hulu') ||
        merchant.contains('cinema') ||
        merchant.contains('theater')) {
      return 'Entertainment';
    } else if (merchant.contains('restaurant') ||
        merchant.contains('cafe') ||
        merchant.contains('doordash') ||
        merchant.contains('uber eats')) {
      return 'Food';
    } else if (merchant.contains('doctor') ||
        merchant.contains('pharmacy') ||
        merchant.contains('hospital')) {
      return 'Health';
    } else if (merchant.contains('utility') ||
        merchant.contains('electric') ||
        merchant.contains('water') ||
        merchant.contains('phone') ||
        merchant.contains('bill')) {
      return 'Bills';
    }
    return 'Other';
  }

  String _parseDate(String dateStr) {
    // Convert MM/DD/YYYY to YYYY-MM-DD for DateTime.parse
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';
    }
    return DateTime.now().toIso8601String().split('T')[0];
  }
}

class Expense {
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final String? source;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.source,
  });
}

class BankMessage {
  final String content;
  final DateTime date;
  final String merchant;
  final double amount;

  BankMessage(this.content, this.date, this.merchant, this.amount);
}

class SettingsItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  SettingsItem(this.title, this.subtitle, this.icon, this.onTap);
}