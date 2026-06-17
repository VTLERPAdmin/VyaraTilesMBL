// =========================================
// SO APPROVAL SCREEN (CLEAN MOBILE UI)
// =========================================
import '../services/session_manager.dart';
import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../models/so_approval_model.dart';
import 'so_approval_detail_screen.dart';
import 'package:intl/intl.dart';


class SOApprovalScreen extends StatefulWidget {
  const SOApprovalScreen({super.key});

  @override
  State<SOApprovalScreen> createState() => _SOApprovalScreenState();
}

class _SOApprovalScreenState extends State<SOApprovalScreen> {
  bool loading = true;
  List<SOApprovalModel> soList = [];

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
    loadSOList();
  }
Future<void> loadSOList() async {
 /* LoaderService.show(
    context,
    title: "Loading",
    subtitle: "Fetching SO List...",
  ); */

  try {
    final userId = await SessionManager.getUserId();

    final data = await ApiService.getSOApprovalList(
      userId: userId,
    );

    if (!mounted) return;

    setState(() {
      soList = data.where((e) => e.approved == false).toList();
    });

  } catch (e) {
    print("SO Error: $e");

    if (!mounted) return;

    setState(() {
      soList = [];
    });

  } finally {
    //LoaderService.hide();
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
        title: const Text("SO Approval",
            style: TextStyle(color: Colors.white)),
        iconTheme:
            const IconThemeData(color: Colors.white),
      ),

      body: 
         soList.isEmpty
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
                  Icons.task_alt_rounded,
                  color: Color(0xFF06224D),
                  size: 32,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "All SOs Approved",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF06224D),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "There are no pending sales orders awaiting approval today.",
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
                            builder: (_) =>
                                SOApprovalDetailScreen(so: so),
                          ),
                        ).then((_) => loadSOList());
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                            /*
                            /// TOP ROW
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  so.soNo,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold),
                                ),

                                /// ❗ ONLY SHOW IF REVISION > 0
                                if (rev > 0)
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          getRevColor(rev)
                                              .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Rev $rev",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: getRevColor(rev),
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ), */

                            const SizedBox(height: 8),

                            Text(
                              so.client,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              so.siteName,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey),
                            ),

                            const SizedBox(height: 10),

                            Row(
                              children: [
                                const Icon(Icons.person,
                                    size: 16,
                                    color: Colors.grey),
                                const SizedBox(width: 5),
                                Text(so.mktPerson,
                                    style: const TextStyle(
                                        color: Colors.grey)),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey),
                                const SizedBox(width: 5),
                                Text(formatDate(so.soDate),
                                    style: const TextStyle(
                                        color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}