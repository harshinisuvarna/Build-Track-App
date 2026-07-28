import os
import re

def update_fulfillment():
    path = r'C:\build-track\Build-Track-App\lib\screen\inventory\fulfillment_payment_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add _phase and _activity to state variables
    state_vars_insert = "  late String? _phase;\n  late String? _activity;\n"
    content = content.replace("  late String? _existingReceipt;\n", "  late String? _existingReceipt;\n" + state_vars_insert)

    # 2. Extract in didChangeDependencies
    extract_insert = """
    final txDetails = args['transactionDetails'] as Map?;
    _phase = (txDetails?['phase'] ?? txDetails?['phaseName'])?.toString();
    _activity = (txDetails?['activity'] ?? txDetails?['activityName'])?.toString();
"""
    content = content.replace("    _uploadedReceipt = _existingReceipt;\n  }", "    _uploadedReceipt = _existingReceipt;\n" + extract_insert + "  }")

    # 3. Add to meta
    meta_insert = """      if (_phase != null && _phase!.isNotEmpty) 'phase': _phase,
      if (_activity != null && _activity!.isNotEmpty) 'activity': _activity,
"""
    content = content.replace("      'projectName': _projectName,\n      'itemName': _itemName,\n", "      'projectName': _projectName,\n      'itemName': _itemName,\n" + meta_insert)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

update_fulfillment()
print("Updated fulfillment_payment_screen.dart")
