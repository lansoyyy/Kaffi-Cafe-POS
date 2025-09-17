import 'package:get_storage/get_storage.dart';

class BranchService {
  static const String _branchKey = 'selected_branch';
  static final GetStorage _storage = GetStorage();

  // Save the selected branch to storage
  static Future<void> saveSelectedBranch(String branch) async {
    await _storage.write(_branchKey, branch);
  }

  // Get the selected branch from storage
  static String? getSelectedBranch() {
    return _storage.read<String>(_branchKey);
  }

  // Check if a branch has been selected
  static bool isBranchSelected() {
    return getSelectedBranch() != null;
  }

  // Clear the selected branch from storage
  static Future<void> clearSelectedBranch() async {
    await _storage.remove(_branchKey);
  }
}
