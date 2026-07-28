import os
import re

def update_fulfillment():
    path = r'c:\build-track\Build-Track-App\lib\screen\inventory\fulfillment_payment_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add state variables
    state_vars = """
  bool _isEsignPolling = false;
  bool _isEsignCompleted = false;
  String _esignStatusText = '';

  Future<void> _startEsignFlow() async {
    if (_clientEmailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter client email')));
      return;
    }
    setState(() {
      _isEsignPolling = true;
      _esignStatusText = 'Sending request...';
    });
    
    final meta = {
      'projectName': _projectName,
      'type': _itemType,
      'amount': _parseAmount(_amountCtrl.text) ?? 0.0,
      'date': _selectedPaymentDate.toIso8601String(),
    };

    final res = await ApiService.requestEsignature(_clientEmailCtrl.text.trim(), meta);
    if (res == null || res['requestId'] == null) {
      setState(() {
        _isEsignPolling = false;
        _esignStatusText = 'Failed to send request';
      });
      return;
    }
    
    setState(() {
      _esignStatusText = 'Waiting for client to sign...';
    });
    
    final reqId = res['requestId'];
    
    while (_isEsignPolling) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || !_isEsignPolling) break;
      
      final statusRes = await ApiService.checkEsignatureStatus(reqId);
      if (statusRes != null && statusRes['status'] == 'signed') {
        if (mounted) {
          setState(() {
            _isEsignPolling = false;
            _isEsignCompleted = true;
            _newReceiptDataUri = statusRes['signatureData'];
            _esignStatusText = 'Signature captured!';
          });
        }
        break;
      }
    }
  }
"""
    if "bool _isEsignPolling = false;" not in content:
        content = content.replace("final _clientEmailCtrl = TextEditingController();", "final _clientEmailCtrl = TextEditingController();\n" + state_vars)

    # Add UI buttons
    ui_logic = """
                      if (_requestEsign && !_isEsignCompleted) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isEsignPolling ? () {
                              setState(() => _isEsignPolling = false);
                            } : _startEsignFlow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isEsignPolling ? Colors.red : const Color(0xFF173EEA),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(_isEsignPolling ? 'Cancel Polling' : 'Send for E-Signature', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (_esignStatusText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_esignStatusText, style: TextStyle(color: _isEsignPolling ? Colors.orange : (_isEsignCompleted ? Colors.green : Colors.red), fontWeight: FontWeight.bold)),
                          )
                      ],
                      if (_isEsignCompleted) ...[
                         const SizedBox(height: 8),
                         Container(
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)),
                           child: const Row(
                             children: [
                               Icon(Icons.check_circle, color: Colors.green),
                               SizedBox(width: 8),
                               Text('Signature successfully captured!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                             ]
                           )
                         )
                      ],
                      """
    if "_isEsignCompleted" not in content.split("TextField(\n                            controller: _clientEmailCtrl")[1]:
        content = content.replace("), // TextField", "),\n" + ui_logic, 1) # Wait, it's safer with regex
        
        # Regex replacement for the TextField closing block
        content = re.sub(
            r"(style: const TextStyle\(fontSize: 14, color: _kDark, fontWeight: FontWeight.w500\),\n\s*\),\n\s*\),)",
            r"\1" + "\n" + ui_logic,
            content
        )
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)


def update_entry_widgets():
    path = r'c:\build-track\Build-Track-App\lib\common\widgets\entry_widgets.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    state_vars = """
  bool isEsignPolling = false;
  bool isEsignCompleted = false;
  String esignStatusText = '';
  
  Future<void> startEsignFlow(StateSetter ss) async {
    if (emailCtrl.text.isEmpty) return;
    ss(() {
      isEsignPolling = true;
      esignStatusText = 'Sending request...';
    });
    
    final meta = {
      'projectName': entryTitle,
      'type': category,
      'amount': double.tryParse(amountCtrl.text) ?? 0.0,
      'date': selectedPaymentDate.toIso8601String(),
    };

    final res = await ApiService.requestEsignature(emailCtrl.text.trim(), meta);
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
          uploadedReceiptDataUri = statusRes['signatureData'];
          esignStatusText = 'Signature captured!';
        });
        break;
      }
    }
  }
"""
    if "bool isEsignPolling = false;" not in content:
        content = content.replace("final emailCtrl = TextEditingController();", "final emailCtrl = TextEditingController();\n" + state_vars)

    ui_logic = """
                            if (requestEsign && !isEsignCompleted) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isEsignPolling ? () {
                                    ss(() => isEsignPolling = false);
                                  } : () => startEsignFlow(ss),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isEsignPolling ? Colors.red : const Color(0xFF173EEA),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(isEsignPolling ? 'Cancel Polling' : 'Send for E-Signature', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              if (esignStatusText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(esignStatusText, style: TextStyle(color: isEsignPolling ? Colors.orange : (isEsignCompleted ? Colors.green : Colors.red), fontWeight: FontWeight.bold)),
                                )
                            ],
                            if (isEsignCompleted) ...[
                               const SizedBox(height: 8),
                               Container(
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)),
                                 child: const Row(
                                   children: [
                                     Icon(Icons.check_circle, color: Colors.green),
                                     SizedBox(width: 8),
                                     Text('Signature successfully captured!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                   ]
                                 )
                               )
                            ],
"""
    content = re.sub(
        r"(style: const TextStyle\(fontSize: 14, color: _kDark, fontWeight: FontWeight.w500\),\n\s*\),\n\s*\),)",
        r"\1" + "\n" + ui_logic,
        content
    )
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

update_fulfillment()
update_entry_widgets()
print("Done.")
