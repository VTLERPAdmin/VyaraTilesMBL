import 'package:flutter/material.dart';

class PrevMntSparesPage extends StatelessWidget {
  const PrevMntSparesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Spares Inventory"),
        backgroundColor: const Color(0xFF06224D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            // ================= SUMMARY CARDS =================
            Row(
              children: [
                _buildSummaryCard(
                  "Total Items",
                  "128",
                  Colors.blue,
                ),
                const SizedBox(width: 10),
                _buildSummaryCard(
                  "Low Stock",
                  "12",
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                _buildSummaryCard(
                  "Out of Stock",
                  "5",
                  Colors.orange,
                ),
                const SizedBox(width: 10),
                _buildSummaryCard(
                  "Categories",
                  "8",
                  Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= LIST TITLE =================
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Spare Items",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ================= LIST =================
            Expanded(
              child: ListView(
                children: const [
                  PrevMntSpareItem(
                    name: "Hydraulic Pump Seal",
                    stock: 5,
                    minStock: 10,
                  ),
                  PrevMntSpareItem(
                    name: "Bearing 6205",
                    stock: 20,
                    minStock: 15,
                  ),
                  PrevMntSpareItem(
                    name: "Motor Belt",
                    stock: 2,
                    minStock: 10,
                  ),
                  PrevMntSpareItem(
                    name: "Valve Kit",
                    stock: 0,
                    minStock: 5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class PrevMntSpareItem extends StatelessWidget {
  final String name;
  final int stock;
  final int minStock;

  const PrevMntSpareItem({
    super.key,
    required this.name,
    required this.stock,
    required this.minStock,
  });

  @override
  Widget build(BuildContext context) {
    bool lowStock = stock <= minStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          // NAME
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // STOCK BADGE
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: lowStock ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Stock: $stock",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}