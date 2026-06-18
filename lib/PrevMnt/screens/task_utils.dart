class TaskUtils {
  // ================= STATUS CONSTANTS =================
  static const int pending = 0;
  static const int completed = 1;
  static const int cancelled = 2;

  // ================= CORE LOGIC =================

  /// Treat completed + cancelled as DONE for UI (progress, stats, locking)
  static bool isDone(int statusId) {
    return statusId == completed || statusId == cancelled;
  }

  static bool isCompleted(int statusId) {
    return statusId == completed;
  }

  static bool isCancelled(int statusId) {
    return statusId == cancelled;
  }

  static bool isPending(int statusId) {
    return statusId == pending;
  }

  // ================= UI DISPLAY RULE =================

  /// IMPORTANT:
  /// We hide "Cancelled" in UI and show it as Completed for cleaner dashboard
  static String statusText(int statusId) {
    switch (statusId) {
      case completed:
        return "Completed";
      case cancelled:
        return "Completed"; // UI decision: treat cancel as done
      default:
        return "Pending";
    }
  }

  // ================= COLOR RULE =================

  static String statusKey(int statusId) {
    switch (statusId) {
      case completed:
        return "green";
      case cancelled:
        return "green";
      default:
        return "grey";
    }
  }
}