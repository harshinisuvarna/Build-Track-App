import os

def update_homescreen():
    path = r'c:\build-track\Build-Track-App\lib\screen\dashboard\homescreen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. State variables inside builder
    state_vars = """
        bool isSaving = false;
        bool isEsignPolling = false;
        bool isEsignCompleted = false;
        String esignStatusText = '';
        String clientEmail = '';
        bool requestEsign = false;
        final clientEmailCtrl = TextEditingController();
        String? newReceiptDataUri;

        Future<void> startEsignFlow(StateSetter ss) async {
          final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
          if (amt <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount before requesting an E-Signature')));
            return;
          }
          if (clientEmailCtrl.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter client email')));
            return;
          }
          ss(() {
            isEsignPolling = true;
            esignStatusText = 'Sending request...';
          });
          
          final meta = {
            'projectName': 'BuildTrack Revenue',
            'type': titleCtrl.text.isNotEmpty ? titleCtrl.text : 'Revenue',
            'amount': amt,
            'date': selectedDate.toIso8601String(),
          };

          final res = await ApiService.requestEsignature(clientEmailCtrl.text.trim(), meta);
          if (res == null || res['requestId'] == null) {
            ss(() {
              isEsignPolling = false;
              esignStatusText = 'Failed to send request';
            });
            return;
          }
          
          ss(() {
            esignStatusText = 'Waiting for client to sign...';
          });
          
          final reqId = res['requestId'];
          
          while (isEsignPolling) {
            await Future.delayed(const Duration(seconds: 3));
            if (!isEsignPolling) break;
            
            final statusRes = await ApiService.checkEsignatureStatus(reqId);
            if (statusRes != null && statusRes['status'] == 'signed') {
              ss(() {
                isEsignPolling = false;
                isEsignCompleted = true;
                newReceiptDataUri = statusRes['signatureData'];
                esignStatusText = 'Signature captured!';
              });
              break;
            }
          }
        }
"""
    content = content.replace("bool isSaving = false;", state_vars)
    
    # 2. UI injection below payment mode dropdown
    ui_logic = """
                  if (selectedMode == 'Cash') ...[
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Request E-Signature for Cash Receipt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      value: requestEsign,
                      onChanged: (val) => setModalState(() => requestEsign = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF173EEA),
                    ),
                    if (requestEsign)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: TextField(
                          controller: clientEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Client Email Address',
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF173EEA))),
                          ),
                        ),
                      ),
                    if (requestEsign && !isEsignCompleted) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isEsignPolling ? () {
                            setModalState(() => isEsignPolling = false);
                          } : () => startEsignFlow(setModalState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEsignPolling ? Colors.red : const Color(0xFF173EEA),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isEsignPolling ? 'Cancel Polling' : 'Send for E-Signature', style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                      if (esignStatusText.isNotEmpty)
                        Padding(padding: const EdgeInsets.only(top: 8), child: Text(esignStatusText, style: TextStyle(color: isEsignPolling ? Colors.orange : (isEsignCompleted ? Colors.green : Colors.red), fontWeight: FontWeight.bold)))
                    ],
                    if (isEsignCompleted) ...[
                       const SizedBox(height: 8),
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)),
                         child: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Signature successfully captured!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))])
                       )
                    ],
                  ],
"""
    
    target_str = "                      }\n                    },\n                  ),"
    idx = content.find(target_str)
    if idx != -1:
        insert_idx = idx + len(target_str)
        content = content[:insert_idx] + "\n" + ui_logic + content[insert_idx:]
    
    # 3. Payload update
    target_payload = """
                                  'paidAmount': amount,
                                  'notes': notesCtrl.text.trim(),
"""
    replacement_payload = """
                                  'paidAmount': amount,
                                  'notes': notesCtrl.text.trim(),
                                  if (newReceiptDataUri != null) 'paymentReceipt': newReceiptDataUri,
                                  if (newReceiptDataUri != null) 'receiptImage': newReceiptDataUri,
"""
    content = content.replace(target_payload, replacement_payload)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

update_homescreen()
print("Updated homescreen.")
