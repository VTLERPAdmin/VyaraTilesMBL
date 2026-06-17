import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ev_detail_model.dart';
import '../services/api_services.dart';
import '../services/session_manager.dart';
import '../screens/loader_service.dart';


class EndChargeScreen extends StatefulWidget {
  final EVDetailModel detail;

  const EndChargeScreen({super.key, required this.detail});

  @override
  State<EndChargeScreen> createState() => _EndChargeScreenState();
}

class _EndChargeScreenState extends State<EndChargeScreen> {
  final chargeCtrl = TextEditingController();
  final meterCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  File? imageFile;
  bool loading = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  Future<void> submit() async {
  LoaderService.show(
    context,
    title: "Saving Data",
    subtitle: "Please wait while we submit charging details...",
  );

  try {
    final userId = await SessionManager.getUserId();

    String? imageBase64;
    if (imageFile != null) {
      imageBase64 = base64Encode(await imageFile!.readAsBytes());
    }

    final body = {
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

    await ApiService.endCharge(body);

    if (!context.mounted) return;

    Navigator.pop(context, true);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  } finally {
    LoaderService.hide();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF06224D),
        title: const Text("END CHARGING"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(controller: chargeCtrl, decoration: const InputDecoration(labelText: "Charge")),
            TextField(controller: meterCtrl, decoration: const InputDecoration(labelText: "Meter")),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: "Notes")),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 120,
                color: Colors.grey.shade200,
                child: imageFile == null
                    ? const Center(child: Text("Upload Image"))
                    : Image.file(imageFile!, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: submit,
              child: Text(loading ? "Saving..." : "END CHARGE"),
            )
          ],
        ),
      ),
    );
  }
}