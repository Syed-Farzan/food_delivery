import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SetFreeItemThresholdPage extends StatefulWidget {
  const SetFreeItemThresholdPage({Key? key}) : super(key: key);

  @override
  State<SetFreeItemThresholdPage> createState() =>
      _SetFreeItemThresholdPageState();
}

class _SetFreeItemThresholdPageState extends State<SetFreeItemThresholdPage> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  List<Map<String, dynamic>> _thresholds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }

  Future<void> _loadThresholds() async {
    setState(() => _loading = true);
    final snapshot = await FirebaseFirestore.instance
        .collection('free_item_thresholds')
        .orderBy('price')
        .get();
    _thresholds = snapshot.docs
        .map(
          (doc) => {
            'id': doc.id,
            'price': doc['price'] as num,
            'item': doc['item'] as String,
          },
        )
        .toList();
    setState(() => _loading = false);
  }

  Future<void> _addThreshold() async {
    final price = double.tryParse(_priceController.text);
    final item = _itemController.text.trim();
    if (price == null || price < 0 || item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price and item name.'),
        ),
      );
      return;
    }
    await FirebaseFirestore.instance.collection('free_item_thresholds').add({
      'price': price,
      'item': item,
    });
    _priceController.clear();
    _itemController.clear();
    await _loadThresholds();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Threshold added!')));
  }

  Future<void> _removeThreshold(String id) async {
    await FirebaseFirestore.instance
        .collection('free_item_thresholds')
        .doc(id)
        .delete();
    await _loadThresholds();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Free Item Thresholds'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Add price thresholds (in ₹) and the free item to be given when a customer\'s cart exceeds that price.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Threshold Price (₹)',
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(
                      labelText: 'Free Item Name',
                      prefixIcon: Icon(Icons.card_giftcard),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addThreshold,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _thresholds.isEmpty
                  ? const Center(child: Text('No thresholds set yet.'))
                  : ListView.builder(
                      itemCount: _thresholds.length,
                      itemBuilder: (context, index) {
                        final threshold = _thresholds[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(
                              Icons.currency_rupee,
                              color: Colors.black,
                            ),
                            title: Text(
                              '₹${threshold['price'].toStringAsFixed(2)} - ${threshold['item']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _removeThreshold(threshold['id']),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
