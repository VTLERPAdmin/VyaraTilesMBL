import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/PrevMnt_api_services.dart';

class PrevMntTaskScreen extends StatefulWidget {
  
  final int empId;
  final int eqId;

  const PrevMntTaskScreen({
    super.key,
    required this.empId,
    required this.eqId,
  });

  @override
  State<PrevMntTaskScreen> createState() =>
      _PrevMntTaskScreenState();
}



class _PrevMntTaskScreenState
    extends State<PrevMntTaskScreen> {

  bool loading = true;

  List tasks = [];
  Map<int, bool> cancelledTasks = {};

  Map<int, bool> completedTasks = {};

  Map<int, TextEditingController>
      noteControllers = {};

  Map<int, File?> selectedImages = {};

  bool saving = false;

 bool isLocked(int index) {
  
  int status = tasks[index]["StatusID"] ?? 0;

  // 1 = completed, 2 = cancelled
  return status == 1 || status == 2;
}


  final ImagePicker picker =
      ImagePicker();

  String eqName = "";

  String eqType = "";

  @override
  void initState() {
    super.initState();

    fetchTasks();
  }


    // ======== cancel button ========
void toggleCancel(int index) {
  setState(() {
    cancelledTasks[index] = !(cancelledTasks[index] ?? false);

    if (cancelledTasks[index] == true) {
      completedTasks[index] = false;
    }
  });
}


    
  // ================= FETCH TASKS =================

  Future<void> fetchTasks() async {

    try {

      final res =
          await PrevMntApiService.getTaskList(
        widget.empId,
        widget.eqId,
      );

      tasks = res["Tasks"] ?? [];
      completedTasks.clear();
cancelledTasks.clear();
noteControllers.clear();

for (int i = 0; i < tasks.length; i++) {
  int status = tasks[i]["StatusID"] ?? 0;

  completedTasks[i] = status == 1;
  cancelledTasks[i] = status == 2;

  noteControllers[i] = TextEditingController(
    text: tasks[i]["EmpNotes"] ?? "",
  );
}


      if (tasks.isNotEmpty) {

        eqName =
            tasks[0]["EqName"] ?? "";

        eqType =
            tasks[0]["EqType"] ?? "";
      }

      for (int i = 0;
          i < tasks.length;
          i++) {

                      if (cancelledTasks[i] == true &&
              (noteControllers[i]?.text ?? "").trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Cancel note required for all cancelled tasks",
                ),
              ),
            );
            setState(() => saving = false);
            return;
          }

        completedTasks[i] =
    (tasks[i]["StatusID"] ?? 0) == 1;

        noteControllers[i] =
            TextEditingController(
          text:
              tasks[i]["EmpNotes"] ??
                  "",
        );
      }
    }

    catch (e) {

      debugPrint(e.toString());
    }

    setState(() {

      loading = false;
    });
  }

  // ================= PICK IMAGE =================

  Future<void> pickImage(
    int index,
    ImageSource source,
  ) async {

    final XFile? image =
        await picker.pickImage(
      source: source,
      imageQuality: 60,
    );

    if (image != null) {

      setState(() {

        selectedImages[index] =
            File(image.path);
      });
    }
  }

  // ========== All Task completed ============
bool isAllDoneOrCancelled() {
  if (tasks.isEmpty) return false;

  return tasks.every((t) =>
      (t["StatusID"] ?? 0) == 1 ||
      (t["StatusID"] ?? 0) == 2);
}
  // ================= SAVE TASKS =================

  Future<void> saveTasks({
  required bool finalSubmit,
}) async {
  try {
    setState(() {
      saving = true;
    });

    for (int i = 0; i < tasks.length; i++) {
      String note = noteControllers[i]?.text ?? "";

      bool isCancelled = cancelledTasks[i] == true;
      bool isCompleted = completedTasks[i] == true;

      // ================= VALIDATION =================

      if (isCancelled && note.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please write a note to cancel task"),
          ),
        );
        setState(() => saving = false);
        return;
      }

      // ================= STATUS LOGIC =================

      if (isCancelled) {
        tasks[i]["StatusID"] = 2;
        tasks[i]["Status"] = "Cancelled";
      } else if (isCompleted) {
        tasks[i]["StatusID"] = 1;
        tasks[i]["Status"] = "Completed";
      } else {
        tasks[i]["StatusID"] = 0;
        tasks[i]["Status"] = "Pending";
      }

      tasks[i]["EmpNotes"] = note;

      // employee id only when completed
     if ((isCompleted || isCancelled) &&
    (tasks[i]["TaskEmpID"] == null ||
     tasks[i]["TaskEmpID"] == 0)) {
  tasks[i]["TaskEmpID"] = widget.empId;
}



    }

    final response = await PrevMntApiService.saveTask(tasks);

    if (response["StatusCode"] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            finalSubmit
                ? "Checklist submitted successfully"
                : "Saved successfully",
          ),
        ),
      );
          Navigator.pop(context, true);
     await PrevMntApiService.getTaskList(widget.empId, widget.eqId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["Message"] ?? "Failed"),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  } finally {
    setState(() {
      saving = false;
    });
  }
}

  // ================= DATE =================

  String getTodayDate() {

    final now = DateTime.now();

    return
        "${now.day}-${now.month}-${now.year}";
  }

  // ================= COMPLETED =================

 int getDoneCount() {

  int completed =
      completedTasks.values
          .where((e) => e == true)
          .length;

  int cancelled =
      cancelledTasks.values
          .where((e) => e == true)
          .length;

  return completed + cancelled;
}
  // ================= STATUS =================

  String getStatus() {

    int completed =
       getDoneCount();

    if (completed == 0) {

      return "Pending";
    }

    else if (completed ==
        tasks.length) {

      return "Completed";
    }
    

    return "In Progress";
  }

  // ================= STATUS COLOR =================

  Color getStatusColor() {

    String status = getStatus();

    if (status == "Completed") {

      return Colors.green;
    }

    if (status == "In Progress") {

      return Colors.orange;
    }

    return Colors.grey;
  }
// =============================UI===========================================
  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFF4F6FA),

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
            const Color(0xFF0B1F4D),

        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),

        centerTitle: true,

        title: const Text(

          "VTL Gangad",

          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),

      body: loading
    ? const Center(child: CircularProgressIndicator())

    : isAllDoneOrCancelled()
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Icon(
                  Icons.check_circle,
                  size: 90,
                  color: Colors.green,
                ),

                const SizedBox(height: 10),

                const Text(
                  "All tasks for today completed",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          )

        

          : Column(

            

              children: [



                // ================= HEADER =================

                Container(

                  width: double.infinity,

                  color: Colors.white,

                  padding:
                      const EdgeInsets
                          .all(20),

                  child: Column(

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      GestureDetector(

                        onTap: () {

                          Navigator.pop(
                              context);
                        },

                        child: const Row(

                          children: [

                         /*   Icon(
                              Icons.arrow_back,

                              size: 18,

                              color: Color(
                                

                            SizedBox(width: 5),

                            Text(
                              "Back",

                              style:
                                  TextStyle(
                                color: Color(
                                    0xFF0B1F4D),
                              ),
                            ),*/
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 14),

                      Center(

                        child: Column(

                          children: [

                            Text(

                              eqName,

                              textAlign:
                                  TextAlign
                                      .center,

                              style:
                                  const TextStyle(

                                fontSize:
                                    22,

                                fontWeight:
                                    FontWeight
                                        .w700,

                                color: Color(
                                    0xFF0B1F4D),
                              ),
                            ),

                            const SizedBox(
                                height: 5),

                            Text(

                              eqType,

                              style:
                                  const TextStyle(

                                color:
                                    Colors.grey,

                                fontSize:
                                    14,
                              ),
                            ),

                            const SizedBox(
                                height: 5),

                            Text(

                              getTodayDate(),

                              style:
                                  const TextStyle(

                                color:
                                    Colors.grey,

                                fontSize:
                                    13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                          height: 20),

                      Row(

                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [

                          Text(

                            "${getDoneCount()} of ${tasks.length} complete",

                            style:
                                const TextStyle(

                              color:
                                  Colors.grey,

                              fontSize:
                                  13,
                            ),
                          ),

                          Container(

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),

                            decoration:
                                BoxDecoration(

                              color:
                                  getStatusColor()
                                      .withOpacity(
                                          0.15),

                              borderRadius:
                                  BorderRadius.circular(
                                      30),
                            ),

                            child: Text(

                              getStatus(),

                              style:
                                  TextStyle(

                                color:
                                    getStatusColor(),

                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 12),

                      ClipRRect(

                        borderRadius:
                            BorderRadius
                                .circular(
                                    20),

                        child:
                            LinearProgressIndicator(

                          value: tasks.isEmpty
                              ? 0
                              : getDoneCount() /
                                  tasks.length,

                          minHeight: 8,

                          backgroundColor:
                              Colors.grey
                                  .shade300,

                          valueColor:
                              const AlwaysStoppedAnimation(
                            Color(
                                0xFF26C281),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= TASK LIST =================

                Expanded(

                  child:
                      SingleChildScrollView(                 
                  

                    padding:
                        const EdgeInsets
                            .all(16),

                    child: Container(

                      padding:
                          const EdgeInsets
                              .all(18),

                      decoration:
                          BoxDecoration(

                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius
                                .circular(
                                    24),

                        boxShadow: [

                          BoxShadow(

                            color: Colors
                                .black
                                .withOpacity(
                                    0.04),

                            blurRadius:
                                10,

                            offset:
                                const Offset(
                                    0, 3),
                          ),
                        ],
                      ),

                      child: Column(

                        children: List.generate(
                          tasks.length,

                          (index) {

                            final t =
                                tasks[index];

                            bool completed =
                                completedTasks[
                                        index] ==
                                    true;

                            return Column(

                              children: [

                                Row(

                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [

                                    GestureDetector(
                                  onTap: isLocked(index)
                                      ? null
                                      : () {
                                    setState(() {                                  

                                      // Toggle completed
                                      completedTasks[index] =
                                          !(completedTasks[index] ?? false);
                                    });
                                  },
                                      


                                      child: Container(

                                        margin:
                                            const EdgeInsets
                                                .only(
                                          top: 2,
                                        ),

                                        

                                        child: Icon(
                                                  tasks[index]["StatusID"] == 1
                                                      ? Icons.check_circle
                                                      : tasks[index]["StatusID"] == 2
                                                          ? Icons.cancel
                                                          : Icons.radio_button_unchecked,
                                                

                                              color: cancelledTasks[index] == true
                                                  ? Colors.red
                                                  : (completedTasks[index] == true
                                                      ? Colors.green
                                                      : Colors.grey),

                                              size: 28,
                                            ),
                                      ),
                                    ),

                                    const SizedBox(
                                        width:
                                            14),

                                    Expanded(

                                      child:
                                          Column(

                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,

                                        children: [

                                          Text(

                                            t["TaskHeading"] ??
                                                "-",

                                            style:
                                                TextStyle(

                                              fontSize:
                                                  15,

                                              fontWeight:
                                                  FontWeight.w600,

                                              decoration:
                                                  completed
                                                      ? TextDecoration.lineThrough
                                                      : null,

                                              color:
                                                  completed
                                                      ? Colors.grey
                                                      : Colors.black,
                                            ),
                                          ),

                                          if ((t["TaskNarration"] ??
                                                  "")
                                              .toString()
                                              .isNotEmpty)

                                            Padding(

                                              padding:
                                                  const EdgeInsets.only(
                                                top:
                                                    6,
                                              ),

                                              child:
                                                  Text(

                                                t["TaskNarration"],

                                                style:
                                                    TextStyle(

                                                  color:
                                                      completed
                                                          ? Colors.grey
                                                          : Colors.black54,

                                                  height:
                                                      1.4,

                                                  decoration:
                                                      completed
                                                          ? TextDecoration.lineThrough
                                                          : null,
                                                ),
                                              ),
                                            ),

                                          const SizedBox(
                                              height:
                                                  12),

                                          // ================= NOTES =================

                                          TextField(

                                            controller:
                                                noteControllers[
                                                    index],
                                             enabled: !isLocked(index),

                                            maxLines:
                                                2,

                                            decoration:
                                                InputDecoration(

                                              hintText:
                                                  "Add note",

                                              filled:
                                                  true,

                                              fillColor:
                                                  completed
                                                      ? Colors.green.withOpacity(
                                                          0.08)
                                                      : Colors.grey.shade100,

                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal:
                                                    14,

                                                vertical:
                                                    12,
                                              ),

                                              border:
                                                  OutlineInputBorder(

                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),

                                                borderSide:
                                                    BorderSide.none,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(
                                              height:
                                                  12),

                                          // ================= IMAGE =================

                                          if (selectedImages[
                                                  index] !=
                                              null)

                                            ClipRRect(

                                              borderRadius:
                                                  BorderRadius.circular(
                                                      12),

                                              child:
                                                  Image.file(

                                                selectedImages[
                                                    index]!,

                                                height:
                                                    120,

                                                width:
                                                    double.infinity,

                                                fit: BoxFit
                                                    .cover,
                                              ),
                                            ),

                                          const SizedBox(
                                              height:
                                                  10),

                                          Row(

                                            children: [

                                              OutlinedButton.icon(

                                               onPressed: isLocked(index)
                                                    ? null
                                                    : () {

                                                  pickImage(
                                                    index,

                                                    ImageSource.camera,
                                                  );
                                                },                                               

                                                style:
                                                    OutlinedButton.styleFrom(

                                                  foregroundColor:
                                                      const Color(
                                                          0xFF0B1F4D),

                                                  side:
                                                      BorderSide(
                                                    color:
                                                        Colors.grey.shade300,
                                                  ),

                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                ),

                                                icon:
                                                    const Icon(
                                                  Icons.camera_alt_outlined,

                                                  size:
                                                      18,
                                                ),

                                                label:
                                                    const Text(
                                                  "Photo",
                                                ),
                                              ),

                                              const SizedBox(
                                                  width:
                                                      10),

                                                 const SizedBox(width: 10),

                              OutlinedButton.icon(
                               onPressed: isLocked(index)
                                          ? null
                                          : () {
                                              String note =
                                                  noteControllers[index]?.text ?? "";

                                              if (note.trim().isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Please write a note before cancelling task",
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                  setState(() {
                                    // toggle cancel
                                    cancelledTasks[index] = !(cancelledTasks[index] ?? false);

                                    // if cancelled → remove completed
                                    if (cancelledTasks[index] == true) {
                                      completedTasks[index] = false;
                                    }
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 18,
                                ),
                                label: const Text("Cancel"),
                              ),     

                                              if (selectedImages[
                                                      index] !=
                                                  null)

                                                Text(

                                                  "1 photo",

                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.grey.shade600,

                                                    fontSize:
                                                        12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                  
                                  ],
                                ),

                                if (index !=
                                    tasks.length -
                                        1)

                                  Padding(

                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      vertical: 18,
                                    ),

                                    child: Divider(
                                      color: Colors
                                          .grey
                                          .shade300,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // ================= BOTTOM =================

                Container(

                  color: Colors.white,

                  padding:
                      const EdgeInsets
                          .all(16),

                  child: Column(

                    children: [

                      // ================= SUBMIT =================

                      SizedBox(

                        width:
                            double.infinity,

                        height: 55,

                        child:
                            ElevatedButton(

                          onPressed: saving

                              ? null

                              : () {

                                  saveTasks(
                                    finalSubmit:
                                        true,
                                  );
                                },

                          style:
                              ElevatedButton
                                  .styleFrom(

                            backgroundColor:
                                const Color(
                                    0xFF0B1F4D),

                            shape:
                                RoundedRectangleBorder(

                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                            ),
                          ),

                          child: saving

                              ? const SizedBox(

                                  height:
                                      20,

                                  width:
                                      20,

                                  child:
                                      CircularProgressIndicator(

                                    color:
                                        Colors.white,

                                    strokeWidth:
                                        2,
                                  ),
                                )

                              : const Text(

                                  "Submit Checklist",

                                  style:
                                      TextStyle(

                                    fontSize:
                                        16,

                                    fontWeight:
                                        FontWeight.w600,

                                    color:
                                        Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(
                          height: 12),

                      // ================= SAVE LATER =================

                      
                       
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}