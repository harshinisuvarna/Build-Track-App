import 'package:flutter/material.dart';

class UpdateProgressScreen extends StatefulWidget {
  const UpdateProgressScreen({super.key});

  @override
  State<UpdateProgressScreen> createState() => _UpdateProgressScreenState();
}

class _UpdateProgressScreenState extends State<UpdateProgressScreen> {
  static const primaryBlue = Color(0xFF2233DD);
  static const bgColor = Color(0xFFF4F6FB);
  static const textDark = Color(0xFF0F1724);
  static const textGray = Color(0xFF7B8A9E);

  int _selectedNavIndex = 1;
  int _stageIndex = 0;
  final _stages = ['Reinforcement', 'Formwork', 'Curing'];
  final TextEditingController _progressCtrl = TextEditingController();

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentStageCard(),
                    const SizedBox(height: 22),
                    _buildSelectStage(),
                    const SizedBox(height: 22),
                    _buildProgressDetailsField(),
                    const SizedBox(height: 20),
                    _buildDateField(),
                    const SizedBox(height: 20),
                    _buildDocumentation(),
                    const SizedBox(height: 20),
                    _buildMaterialConsumption(context),
                    const SizedBox(height: 30),
                    _buildSaveButton(context),
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
          const Text('Update progress',
              style: TextStyle(
                  color: textDark, fontSize: 17, fontWeight: FontWeight.w800)),
          CircleAvatar(
            radius: 19,
            backgroundColor: Colors.blue.shade700,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStageCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('CURRENT ACTIVE STAGE',
                style: TextStyle(
                    color: primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Reinforcement Work',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                        letterSpacing: -0.4,
                        height: 1.2)),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.architecture, color: textGray, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: textGray, size: 14),
              SizedBox(width: 4),
              Text('Sector B-12 • Level 04',
                  style: TextStyle(
                      color: textGray, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('COMPLETION',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: textGray,
                                letterSpacing: 0.5)),
                        Text('65%',
                            style: TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.w900,
                                fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: 0.65,
                        backgroundColor: Color(0xFFE8ECF8),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(primaryBlue),
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _avatarStack(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarStack() {
    const colors = [Color(0xFF5B6CF6), Color(0xFF9C59B5)];
    return Row(
      children: [
        ...List.generate(2, (i) {
          return Transform.translate(
            offset: Offset(i * -9.0, 0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: colors[i],
              child: const Icon(Icons.person, color: Colors.white, size: 14),
            ),
          );
        }),
        Transform.translate(
          offset: const Offset(-18, 0),
          child: const CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFFEEF0FF),
            child: Text('+4',
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w800, color: primaryBlue)),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectStage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Stage',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900, color: textDark)),
        const SizedBox(height: 12),
        Row(
          children: _stages.asMap().entries.map((e) {
            final sel = e.key == _stageIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _stageIndex = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8)
                    ],
                  ),
                  child: Text(e.value,
                      style: TextStyle(
                          color: sel ? Colors.white : textGray,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProgressDetailsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Work progress details',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900, color: textDark)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE0F0), width: 1.5),
          ),
          child: TextField(
            controller: _progressCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Describe the tasks completed today...',
              hintStyle: TextStyle(color: textGray, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
            style:
                const TextStyle(fontSize: 14, color: textDark, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Update Date',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900, color: textDark)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE0F0), width: 1.5),
          ),
          child: const Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: primaryBlue, size: 19),
              SizedBox(width: 10),
              Text('October 24, 2023',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: textDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Documentation',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900, color: textDark)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera / file picker would open here')),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: const Color(0xFFCCCFE8), width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF0FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: primaryBlue, size: 24),
                ),
                const SizedBox(height: 9),
                const Text('Upload site photos',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: textDark)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // FIX: added context param so ADD MATERIAL button can navigate
  Widget _buildMaterialConsumption(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MATERIAL CONSUMPTION',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: textGray,
                      letterSpacing: 0.7)),
              TextButton(
                // FIX: ADD MATERIAL now navigates to add-material screen
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/add-material',
                  arguments: {'type': 'material'},
                ),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('ADD MATERIAL',
                    style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _materialTag('Rebar 12mm', '120 kg'),
          const SizedBox(height: 8),
          _materialTag('Concrete M30', '12 m³'),
        ],
      ),
    );
  }

  Widget _materialTag(String label, String qty) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14.5, color: textDark)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF0FF),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(qty,
              style: const TextStyle(
                  color: primaryBlue, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text('Save progress update',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
          ],
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
              _navItem(context, 1, Icons.architecture_outlined, 'PROJECTS',
                  route: '/projects'),
              _navEntryButton(context),
              _navItem(context, 3, Icons.inventory_2_outlined, 'INVENTORY',
                  route: '/inventory'),
              _navItem(context, 4, Icons.bar_chart_outlined, 'REPORTS',
                  route: '/reports'),
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
        if (route != null) Navigator.pushNamed(context, route);
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
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNavIndex = 2);
        Navigator.pushNamed(context, '/add-entry');
      },
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
                color: _selectedNavIndex == 2 ? primaryBlue : textGray,
                letterSpacing: 0.3,
              )),
        ],
      ),
    );
  }
}