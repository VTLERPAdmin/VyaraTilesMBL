import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ev_detail_model.dart';
import '../services/api_services.dart';
import '../services/session_manager.dart';

class EVDetailScreen extends StatefulWidget {
  final EVDetailModel detail;

  const EVDetailScreen({super.key, required this.detail});

  @override
  State<EVDetailScreen> createState() => _EVDetailScreenState();
}

class _EVDetailScreenState extends State<EVDetailScreen> {
  File? imageFile;
  bool loading = false;

  final chargeCtrl = TextEditingController();
  final meterCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  bool get isStartMode => widget.detail.entryId == 0;

  // ================= IMAGE PICK =================
  Future<void> pickImage() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      final ext = picked.path.split('.').last.toLowerCase();
      if (!(ext == 'jpg' || ext == 'jpeg' || ext == 'png')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Only jpg, jpeg, png allowed")),
        );
        return;
      }

      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  // ================= SUBMIT (UNCHANGED BACKEND) =================
  Future<void> submit() async {
    if (loading) return;

    setState(() => loading = true);

    try {
      final userId = await SessionManager.getUserId();

      String? imageBase64;

      if (imageFile != null) {
        final bytes = await imageFile!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final body = isStartMode
          ? {
              "EntryID": 0,
              "UserName": userId,
              "EqID": widget.detail.eqId,
              "StartInfo": {
                "ReadDate": DateTime.now().toIso8601String(),
                "ChargeReading": double.tryParse(chargeCtrl.text) ?? 0,
                "MeterReading": double.tryParse(meterCtrl.text) ?? 0,
                "Notes": notesCtrl.text,
                "Img": imageBase64,
              }
            }
          : {
              "EntryID": widget.detail.entryId,
              "UserName": userId,
              "EqID": widget.detail.eqId,
              "EndInfo": {
                "ReadDate": DateTime.now().toIso8601String(),
                "ChargeReading": double.tryParse(chargeCtrl.text) ?? 0,
                "MeterReading": double.tryParse(meterCtrl.text) ?? 0,
                "Notes": notesCtrl.text,
                "Img": imageBase64,
              }
            };

      if (isStartMode) {
        await ApiService.startCharge(body);
      } else {
        await ApiService.endCharge(body);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last =
        isStartMode ? widget.detail.endInfo : widget.detail.startInfo;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      
      appBar: AppBar(
        backgroundColor: const Color(0xFF06224D),
        foregroundColor: Colors.white,
        title: Text(isStartMode ? "START CHARGING" : "END CHARGING"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _evMasterCard(last),
            const SizedBox(height: 12),
            _chargingForm(now),
            const SizedBox(height: 20),
            _actionButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ================= MASTER CARD (NEW UI) =================
  Widget _evMasterCard(dynamic last) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.detail.eqName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.detail.eqType),
                    Text(widget.detail.locName),
                  ],
                ),
              ),
              const Icon(Icons.ev_station,
                  size: 55, color: Color(0xFF06224D)),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Current Time : ${DateTime.now()}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStartMode
                          ? "Last End Charge"
                          : "Last Start Charge",
                      style:
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text("Date : ${last.readDate}"),
                    Text("Charge : ${last.chargeReading}%"),
                    Text("Meter : ${last.meterReading} KM"),
                    Text("Notes : ${last.notes}"),
                  ],
                ),
              ),

              SizedBox(
                height: 100,
                width: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: _ArcPainter(last.chargeReading),
                    ),
                    Text(
                      "${last.chargeReading.toInt()}%",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // ================= FORM =================
  Widget _chargingForm(DateTime now) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isStartMode ? "START ENTRY" : "END ENTRY",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF06224D)),
          ),
          const SizedBox(height: 12),

          _field("Charge Reading"),
          _field("Meter Reading"),
          _field("Notes"),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: imageFile == null
                  ? const Center(child: Text("Upload Image"))
                  : Image.file(imageFile!, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUTTON =================
  Widget _actionButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF06224D),
          padding: const EdgeInsets.all(14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: submit,
        child: Text(
          loading
              ? "Please wait..."
              : (isStartMode ? "START CHARGING" : "END CHARGING"),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ================= FIELD =================
  Widget _field(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: label == "Charge Reading"
            ? chargeCtrl
            : label == "Meter Reading"
                ? meterCtrl
                : notesCtrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // ================= CARD STYLE =================
  BoxDecoration _card() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 4),
        )
      ],
    );
  }
}

// ================= ARC PAINTER =================
class _ArcPainter extends CustomPainter {
  final double value;

  _ArcPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bg = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        math.pi, math.pi, false, bg);

    final fg = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final sweep = math.pi * (value / 100);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        math.pi, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}