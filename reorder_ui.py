import os

def reorder_fulfillment():
    path = r'c:\build-track\Build-Track-App\lib\screen\inventory\fulfillment_payment_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # The actual amount paid block
    amount_block_start = "                    const Text(\n                      'ACTUAL AMOUNT PAID (₹)',"
    amount_block_end = "                        ),\n                      ),\n                    ),"
    
    start_idx = content.find(amount_block_start)
    end_idx = content.find(amount_block_end, start_idx) + len(amount_block_end)
    
    if start_idx == -1 or end_idx == -1:
        print("Could not find amount block in fulfillment_payment_screen.dart")
        return
        
    amount_block = content[start_idx:end_idx]
    
    # Remove it from the original place
    content = content[:start_idx] + content[end_idx:]
    
    # Find where to insert it: before PAYMENT METHOD
    payment_method_start = "                    const Text(\n                      'PAYMENT METHOD',"
    insert_idx = content.find(payment_method_start)
    
    if insert_idx == -1:
        print("Could not find payment method block in fulfillment_payment_screen.dart")
        return
        
    content = content[:insert_idx] + amount_block + "\n                    const SizedBox(height: 20),\n\n" + content[insert_idx:]
    
    # Add validation to _startEsignFlow
    validation_code = """
    final amt = _parseAmount(_amountCtrl.text);
    if (amt == null || amt <= 0) {
      setState(() => _amountError = 'Please enter a valid amount before requesting an E-Signature.');
      return;
    }
    """
    
    start_esign_idx = content.find("Future<void> _startEsignFlow() async {")
    if start_esign_idx != -1:
        insert_val_idx = content.find("if (_clientEmailCtrl.text.isEmpty) {", start_esign_idx)
        content = content[:insert_val_idx] + validation_code + "\n    " + content[insert_val_idx:]
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def reorder_entry_widgets():
    path = r'c:\build-track\Build-Track-App\lib\common\widgets\entry_widgets.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    amount_block_start = "                            const Text(\n                              'ACTUAL AMOUNT PAID (₹)',"
    amount_block_end = "                                ),\n                              ),\n                            ),"
    
    start_idx = content.find(amount_block_start)
    end_idx = content.find(amount_block_end, start_idx) + len(amount_block_end)
    
    if start_idx == -1 or end_idx == -1:
        print("Could not find amount block in entry_widgets.dart")
        return
        
    amount_block = content[start_idx:end_idx]
    content = content[:start_idx] + content[end_idx:]
    
    payment_method_start = "                            const Text(\n                              'PAYMENT METHOD',"
    insert_idx = content.find(payment_method_start)
    
    if insert_idx == -1:
        print("Could not find payment method block in entry_widgets.dart")
        return
        
    content = content[:insert_idx] + amount_block + "\n                            const SizedBox(height: 20),\n\n" + content[insert_idx:]
    
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
        content = content[:insert_val_idx] + validation_code + "\n    " + content[insert_val_idx:]

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

reorder_fulfillment()
reorder_entry_widgets()
print("Reordered UI successfully.")
