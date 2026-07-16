import re

file_path = r'c:\build-track\Build-Track-App\lib\screen\manual_voice_entry\updated_progress.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target_1 = '''  Future<void> _fetchDailyTasks() async {
    try {
      final tasks = await TaskService.getDailyTasks();
      if (mounted) {
        bool shouldLoad = false;
        setState(() {
          _dailyTasks = tasks;
          for (var t in tasks) {
            if (t.status == 'Completed') {
              _completedTaskIds.add(t.id);
              if (!shouldLoad && t.activityName != null && t.activityName!.isNotEmpty) {
                if (t.project.isNotEmpty) _selectedProjectId = t.project;
                if (t.floorName != null && t.floorName!.isNotEmpty) _selectedFloor = t.floorName;
                if (t.phaseName != null && t.phaseName!.isNotEmpty) _selectedPhaseName = t.phaseName;
                _selectedActivityName = t.activityName;
                _prefillActivityId = null;
                shouldLoad = true;
              }
            }
          }
          _isLoadingTasks = false;
        });
        if (shouldLoad) {
          _loadActivityDetails();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTasks = false);
    }
  }'''

replacement_1 = '''  Future<void> _fetchDailyTasks() async {
    try {
      final tasks = await TaskService.getDailyTasks();
      if (mounted) {
        setState(() {
          // Filter out completed tasks so they do not show in the checklist
          _dailyTasks = tasks.where((t) => t.status != 'Completed').toList();
          _isLoadingTasks = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTasks = false);
    }
  }'''

content = content.replace(target_1, replacement_1)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done replacing.')
