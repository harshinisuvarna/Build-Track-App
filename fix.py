import re

file_path = r'c:\build-track\Build-Track-App\lib\screen\manual_voice_entry\updated_progress.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Inject _loadActivityDetails before didChangeDependencies
load_act_details_code = '''
  void _loadActivityDetails() {
    if (_selectedProjectId == null || _selectedActivityName == null) return;
    
    final provider = context.read<ProjectProvider>();
    final project = provider.projects.cast<ProjectModel?>().firstWhere(
      (p) => p?.id == _selectedProjectId,
      orElse: () => null,
    );
    
    if (project != null) {
      final matchedAct = project.selectedPhases
          ?.expand((ph) => ph.activities)
          .cast<ProjectActivity?>()
          .firstWhere((act) => act?.id == _prefillActivityId || act?.name == _selectedActivityName, orElse: () => null);
          
      if (matchedAct != null) {
        setState(() {
          if (matchedAct.notes != null && matchedAct.notes!.trim().isNotEmpty) {
            _notesCtrl.text = matchedAct.notes!;
          } else {
            _notesCtrl.clear();
          }
          if (matchedAct.completedAt != null) {
            _selectedDate = matchedAct.completedAt!;
          } else {
            _selectedDate = DateTime.now();
          }
          if (matchedAct.photos != null && matchedAct.photos!.isNotEmpty) {
            _attachments = matchedAct.photos!.map((url) => PhotoAttachment.remote(url)).toList();
          } else if (matchedAct.photo != null && matchedAct.photo!.isNotEmpty) {
            _attachments = [PhotoAttachment.remote(matchedAct.photo!)];
          } else {
            _attachments = [];
          }
        });
      }
    }
  }

  @override
  void didChangeDependencies() {'''

content = content.replace('  @override\n  void didChangeDependencies() {', load_act_details_code)

# 2. Call it in didChangeDependencies
target_1 = '''              // Find matching activity
              final matchedAct = project.selectedPhases
                  ?.expand((ph) => ph.activities)
                  .cast<ProjectActivity?>()
                  .firstWhere((act) => act?.id == activityId || act?.name == activityName, orElse: () => null);
                  
              if (matchedAct != null) {
                if (matchedAct.notes != null && matchedAct.notes!.trim().isNotEmpty) {
                  _notesCtrl.text = matchedAct.notes!;
                }
                if (matchedAct.completedAt != null) {
                  _selectedDate = matchedAct.completedAt!;
                }
                if (matchedAct.photos != null && matchedAct.photos!.isNotEmpty) {
                  _attachments = matchedAct.photos!.map((url) => PhotoAttachment.remote(url)).toList();
                } else if (matchedAct.photo != null && matchedAct.photo!.isNotEmpty) {
                  _attachments = [PhotoAttachment.remote(matchedAct.photo!)];
                }
              }'''

replacement_1 = '''              // Find matching activity and pre-fill details
              _loadActivityDetails();'''

content = content.replace(target_1, replacement_1)

# 3. Call it in CheckboxListTile
target_2 = '''                        if (task.activityName != null && task.activityName!.isNotEmpty) {
                          _selectedActivityName = task.activityName;
                        }'''
replacement_2 = '''                        if (task.activityName != null && task.activityName!.isNotEmpty) {
                          _selectedActivityName = task.activityName;
                          _loadActivityDetails();
                        }'''
content = content.replace(target_2, replacement_2)

# 4. Call it in Activity Dropdown
target_3 = '''                    onChanged:
                        (_selectedPhaseName == null || activityNames.isEmpty)
                        ? null
                        : (val) => setState(() => _selectedActivityName = val),'''
replacement_3 = '''                    onChanged:
                        (_selectedPhaseName == null || activityNames.isEmpty)
                        ? null
                        : (val) {
                            setState(() => _selectedActivityName = val);
                            _loadActivityDetails();
                          },'''
content = content.replace(target_3, replacement_3)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done replacing.')
