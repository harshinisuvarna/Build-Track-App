import re

file_path = r'c:\build-track\Build-Track-App\lib\screen\manual_voice_entry\updated_progress.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _fetchDailyTasks
target_1 = '''  Future<void> _fetchDailyTasks() async {
    try {
      final tasks = await TaskService.getDailyTasks();
      if (mounted) {
        setState(() {
          _dailyTasks = tasks;
          for (var t in tasks) {
            if (t.status == 'Completed') {
              _completedTaskIds.add(t.id);
            }
          }
          _isLoadingTasks = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTasks = false);
    }
  }'''

replacement_1 = '''  Future<void> _fetchDailyTasks() async {
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
content = content.replace(target_1, replacement_1)

# 2. Update _loadActivityDetails firstWhere
target_2 = '''.firstWhere((act) => act?.id == _prefillActivityId || act?.name == _selectedActivityName, orElse: () => null);'''
replacement_2 = '''.firstWhere((act) => (_prefillActivityId != null && act?.id == _prefillActivityId) || (_selectedActivityName != null && act?.name == _selectedActivityName), orElse: () => null);'''
content = content.replace(target_2, replacement_2)

# 3. Clear _prefillActivityId in CheckboxListTile
target_3 = '''                        if (task.activityName != null && task.activityName!.isNotEmpty) {
                          _selectedActivityName = task.activityName;
                          _loadActivityDetails();
                        }'''
replacement_3 = '''                        if (task.activityName != null && task.activityName!.isNotEmpty) {
                          _selectedActivityName = task.activityName;
                          _prefillActivityId = null;
                          _loadActivityDetails();
                        }'''
content = content.replace(target_3, replacement_3)

# 4. Clear _prefillActivityId in Activity Dropdown
target_4 = '''                        : (val) {
                            setState(() => _selectedActivityName = val);
                            _loadActivityDetails();
                          },'''
replacement_4 = '''                        : (val) {
                            setState(() {
                              _selectedActivityName = val;
                              _prefillActivityId = null;
                            });
                            _loadActivityDetails();
                          },'''
content = content.replace(target_4, replacement_4)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done replacing.')
