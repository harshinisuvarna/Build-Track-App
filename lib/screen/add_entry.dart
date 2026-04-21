import 'package:flutter/material.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  int _selectedNavIndex = 2;
  int _selectedEntry = 0; // 0=Material, 1=Labour, 2=Equipment

  final List<Map<String, dynamic>> _entries = [
    {
      'icon': Icons.category,
      'title': 'Material',
      'subtitle': 'Log concrete, steel, lumber, or site-specific procurement items.',
      'type': 'material',
    },
    {
      'icon': Icons.people,
      'title': 'Labour',
      'subtitle': 'Track crew hours, specialized trade performance, and site presence.',
      'type': 'labour',
    },
    {
      'icon': Icons.precision_manufacturing,
      'title': 'Equipment',
      'subtitle': 'Record heavy machinery runtime, fuel logs, and maintenance events.',
      'type': 'equipment',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    const Text(
                      'What are you\nadding?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                          letterSpacing: -0.6,
                          height: 1.15),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Select the entry type to log for the current shift.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: textGray, fontSize: 14.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 34),
                    ...List.generate(_entries.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _entryCard(index),
                      );
                    }),
                    const SizedBox(height: 22),
                    _buildContinueButton(context),
                    const SizedBox(height: 16),
                    // FIX: Save as Draft now pops back instead of doing nothing
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Entry saved as draft'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.maybePop(context);
                      },
                      child: const Text(
                        'Save as Draft',
                        style: TextStyle(
                            color: textGray, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back, color: textDark, size: 22),
          ),
          const Text('Add entry',
              style: TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.w800)),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, color: Colors.grey, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(int index) {
    final entry = _entries[index];
    final isSelected = _selectedEntry == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedEntry = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryBlue.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isSelected ? primaryBlue : const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                entry['icon'] as IconData,
                color: isSelected ? Colors.white : Colors.grey.shade500,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry['title'] as String,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w900, color: textDark)),
                  const SizedBox(height: 5),
                  Text(entry['subtitle'] as String,
                      style: const TextStyle(
                          fontSize: 13, color: textGray, fontWeight: FontWeight.w500, height: 1.4)),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Container(
                width: 26,
                height: 26,
                decoration:
                    const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 15),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return GestureDetector(
      // FIX: passes the selected entry type as an argument to add-material
      onTap: () {
        final selectedType = _entries[_selectedEntry]['type'] as String;
        Navigator.pushNamed(
          context,
          '/add-material',
          arguments: {'type': selectedType},
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2233DD), Color(0xFF5B3FE0)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
                color: primaryBlue.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 5)),
          ],
        ),
        child: const Center(
          child: Text('Continue',
              style: TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _navItem(context, 0, Icons.home_rounded, 'HOME', route: '/home'),
              _navItem(context, 1, Icons.architecture_outlined, 'PROJECTS', route: '/projects'),
              _navEntryButton(context),
              _navItem(context, 3, Icons.inventory_2_outlined, 'INVENTORY', route: '/inventory'),
              _navItem(context, 4, Icons.bar_chart_outlined, 'REPORTS', route: '/reports'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label,
      {String? route}) {
    final isActive = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNavIndex = index);
        if (route != null && route != '/add-entry') {
          Navigator.pushNamed(context, route);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isActive ? primaryBlue : textGray),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isActive ? primaryBlue : textGray,
                    letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _navEntryButton(BuildContext context) {
    final isActive = _selectedNavIndex == 2;
    return GestureDetector(
      // FIX: already on this screen, just highlight it — no push needed
      onTap: () => setState(() => _selectedNavIndex = 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 3),
          Text('ENTRY',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isActive ? primaryBlue : textGray,
                letterSpacing: 0.3,
              )),
        ],
      ),
    );
  }
}