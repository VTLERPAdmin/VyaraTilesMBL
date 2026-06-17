import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/session_manager.dart';
import '../models/so_approval_model.dart';
import '../services/api_services.dart';
import '../screens/loader_service.dart';

class SOApprovalDetailScreen extends StatefulWidget {
  final SOApprovalModel so;

  const SOApprovalDetailScreen({
    super.key,
    required this.so,
  });

  @override
  State<SOApprovalDetailScreen> createState() =>
      _SOApprovalDetailScreenState();
}

class _SOApprovalDetailScreenState
    extends State<SOApprovalDetailScreen> {



  late TextEditingController notesController;

  // ✅ FIX 1: Proper date function inside STATE class
  String formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat("dd-MM-yy").format(dt);
    } catch (e) {
      return date;
    }
  }

  @override
  void initState() {
    super.initState();
    notesController =
        TextEditingController(text: widget.so.notes);
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

Future<void> openPDF() async {
  LoaderService.show(
    context,
    title: "Loading PDF",
    subtitle: "Please wait...",
  );

  try {
    final pdfUrl = await ApiService.getSOPdf(
      userId: "Sys",
      locId: widget.so.locId,
      soId: widget.so.id,
    );

    String url = pdfUrl;
    if (url.startsWith("//")) {
      url = "https:$url";
    }

    LoaderService.hide();

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    LoaderService.hide();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

  

Future<void> approveSO() async {
  /* LoaderService.show(
    context,
    title: "Approving SO",
    subtitle: "Please wait...", ); */

  

  try {
    final userId = await SessionManager.getUserId();

    await ApiService.approveSO(
      userId: userId,   // ✅ dynamic login user
      locId: widget.so.locId,
      soId: widget.so.id,
      notes: notesController.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("SO Approved Successfully"),
      ),
    );

    Navigator.pop(context, true);

  } catch (e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(e.toString()),
      ),
    );
  } 
}

  Widget buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? "-" : value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final so = widget.so;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF06224D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "SO Details",
          style: TextStyle(color: Colors.white),),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            buildInfoCard("SO Number", so.soNo),

            // ✅ FIXED DATE FORMAT
            buildInfoCard("SO Date", formatDate(so.soDate)),

            buildInfoCard("Revision No", so.revisionNo),

            // ✅ FIXED (ONLY ONE LINE)
            buildInfoCard(
              "Revision Date",
              formatDate(so.revisionDate),
            ),

            buildInfoCard("Client", so.client),
            buildInfoCard("Site Name", so.siteName),
            buildInfoCard("Marketing Person", so.mktPerson),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  )
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Notes",
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06224D),
                ),
                onPressed: openPDF,
                icon: const Icon(Icons.picture_as_pdf,
                    color: Colors.white),
                label: const Text(
                  "View PDF",
                 style: TextStyle(color: Colors.white),),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed:
                     approveSO,
                icon: const Icon(Icons.check_circle,
                    color: Colors.white),
                label: const Text(
                  "Approve",
                  style: TextStyle(color: Colors.white),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}