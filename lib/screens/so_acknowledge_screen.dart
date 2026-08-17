import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/so_acknowledgement_model.dart';
import '../services/api_services.dart';
import '../services/session_manager.dart';
import 'so_acknowledge_detail_screen.dart';

class SOAcknowledgeScreen extends StatefulWidget {
  const SOAcknowledgeScreen({super.key});

  @override
  State<SOAcknowledgeScreen> createState() => _SOAcknowledgeScreenState();
}

class _SOAcknowledgeScreenState extends State<SOAcknowledgeScreen> {
  List<SOAcknowledgementModel> soList = [];
  List<SOAcknowledgementModel> allSOList = [];
  late TextEditingController searchController;

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
    searchController = TextEditingController();
    loadSOList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadSOList() async {
  try {
    final session = await SessionManager.getSession();

    if (session == null) {
      throw Exception("Session not found");
    }

    final userId = session["userId"] as String;
    final userPwd = session["password"] as String;

    print("📋 SO ACK LIST SCREEN");
    print("UserID => $userId");
    print("Password loaded => ${userPwd.isNotEmpty}");

    final data = await ApiService.getSOAcknowledgementList(
      userId: userId,
      userPwd: userPwd,
    );

    if (!mounted) return;

    setState(() {
      allSOList = data
          .where((e) => e.approved == true)
          .toList();

      filterSOs();
    });
  } catch (e) {
    print("❌ SO ACK LIST SCREEN ERROR => $e");

    if (!mounted) return;

    setState(() {
      allSOList = [];
      soList = [];
    });
  }
}

  void filterSOs() {
    final query = searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      soList = allSOList;
    } else {
      soList = allSOList.where((so) {
        return so.soNo.toLowerCase().contains(query) ||
               so.client.toLowerCase().contains(query) ||
               so.siteName.toLowerCase().contains(query);
      }).toList();
    }
  }

  Color getRevColor(int rev) {
    if (rev <= 1) return Colors.green;
    if (rev == 2) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06224D),
        title: const Text(
          "SO Acknowledge",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: soList.isEmpty && allSOList.isEmpty
          ? Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06224D).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_outlined,
                        color: Color(0xFF06224D),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "All SOs Acknowledged",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF06224D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "There are no approved sales orders pending acknowledgement.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Search Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        filterSOs();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search by SO No., Client, or Site Name...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  searchController.clear();
                                  filterSOs();
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                // List
                Expanded(
                  child: soList.isEmpty
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06224D).withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.search_off,
                                    color: Color(0xFF06224D),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No Results Found",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF06224D),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "No SOs match your search criteria.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: soList.length,
                          itemBuilder: (context, index) {
                            final so = soList[index];
                            final rev = int.tryParse(so.revisionNo) ?? 0;

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SOAcknowledgeDetailScreen(so: so),
                                  ),
                                ).then((result) {
                                  if (result == true) {
                                    loadSOList();
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            so.soNo,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (rev > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: getRevColor(rev).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              "Rev $rev",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: getRevColor(rev),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      so.client,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      so.siteName,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Text(
                                          so.mktPerson,
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Text(
                                          formatDate(so.soDate),
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
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
