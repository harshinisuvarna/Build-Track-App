import os

def fix_entry_widgets():
    path = r'c:\build-track\Build-Track-App\lib\common\widgets\entry_widgets.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    amount_start = "                              const _SheetSectionLabel(\n                                'ACTUAL AMOUNT PAID (₹)',"
    amount_end = "                              ),\n                              const SizedBox(height: 16),"
    
    start_idx = content.find(amount_start)
    end_idx = content.find(amount_end, start_idx)
    
    if start_idx == -1 or end_idx == -1:
        print("Could not find amount block")
        return
        
    amount_block = content[start_idx:end_idx]
    
    content = content[:start_idx] + content[end_idx:]
    
    payment_method_start = "                              const _SheetSectionLabel('PAYMENT METHOD'),"
    insert_idx = content.find(payment_method_start)
    
    if insert_idx == -1:
        print("Could not find payment method block")
        return
        
    content = content[:insert_idx] + amount_block + "\n" + content[insert_idx:]
    
    validation_code = """
    final amt = double.tryParse(amountCtrl.text);
    if (amt == null || amt <= 0) {
      ss(() => amountError = 'Please enter a valid amount before requesting an E-Signature.');
      return;
    }
    """
    
    start_esign_idx = content.find("Future<void> startEsignFlow(StateSetter ss) async {")
    if start_esign_idx != -1:
        insert_val_idx = content.find("if (emailCtrl.text.isEmpty) return;", start_esign_idx)
        if insert_val_idx != -1:
            content = content[:insert_val_idx] + validation_code + "\n    " + content[insert_val_idx:]

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

fix_entry_widgets()
print("Fixed entry widgets.")
