import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart'; // adjust path if needed

class VulnerabilitiesScreen extends StatefulWidget {
  const VulnerabilitiesScreen({super.key});

  @override
  State<VulnerabilitiesScreen> createState() => _VulnerabilitiesScreenState();
}

class _VulnerabilitiesScreenState extends State<VulnerabilitiesScreen>
    with SingleTickerProviderStateMixin {
  final String repoId = Get.arguments ?? '';

  List<dynamic> vulnerabilities = [];
  bool isLoading = true;
  String? error;
  String selectedFilter = 'ALL';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ─── COLORS ───────────────────────────────────────────────
  static const _bg = Color(0xFF080C18);
  static const _card = Color(0xFF0D1225);
  static const _border = Color(0xFF1A2240);
  static const _muted = Color(0xFF6B7FA3);
  static const _cyan = Color(0xFF00CDD4);
  static const _red = Color(0xFFEF4444);
  static const _orange = Color(0xFFF97316);
  static const _yellow = Color(0xFFEAB308);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetch();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── FETCH via ApiService ─────────────────────────────────
  Future<void> _fetch() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final list = await ApiService.getVulnerabilities(repoId);
      setState(() {
        vulnerabilities = list;
        isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────
  List<dynamic> get _filtered {
    if (selectedFilter == 'ALL') return vulnerabilities;
    return vulnerabilities
        .where(
          (v) =>
              (v['severity'] ?? '').toString().toUpperCase() == selectedFilter,
        )
        .toList();
  }

  Color _color(String s) {
    switch (s.toUpperCase()) {
      case 'HIGH':
        return _red;
      case 'MEDIUM':
        return _orange;
      default:
        return _yellow;
    }
  }

  int _count(String f) => f == 'ALL'
      ? vulnerabilities.length
      : vulnerabilities
            .where((v) => (v['severity'] ?? '').toString().toUpperCase() == f)
            .length;

  // ─── BUILD ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            if (!isLoading && error == null) _summaryRow(),
            if (!isLoading && error == null) _filterChips(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────
  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          _backBtn(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vulnerabilities',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  '${vulnerabilities.length} total found',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          _iconBtn(Icons.refresh, _fetch),
        ],
      ),
    );
  }

  Widget _backBtn() => GestureDetector(
    onTap: () => Get.back(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _cyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cyan.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.arrow_back_ios, color: _cyan, size: 14),
          SizedBox(width: 4),
          Text('Back', style: TextStyle(color: _cyan, fontSize: 13)),
        ],
      ),
    ),
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Icon(icon, color: _cyan, size: 18),
    ),
  );

  // ─── SUMMARY ROW ─────────────────────────────────────────
  Widget _summaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _summaryCard('HIGH', _count('HIGH'), _red),
          const SizedBox(width: 8),
          _summaryCard('MEDIUM', _count('MEDIUM'), _orange),
          const SizedBox(width: 8),
          _summaryCard('LOW', _count('LOW'), _yellow),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int count, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
          ),
        ],
      ),
    ),
  );

  // ─── FILTER CHIPS ────────────────────────────────────────
  Widget _filterChips() {
    final filters = ['ALL', 'HIGH', 'MEDIUM', 'LOW'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final sel = selectedFilter == f;
            final color = f == 'HIGH'
                ? _red
                : f == 'MEDIUM'
                ? _orange
                : f == 'LOW'
                ? _yellow
                : _cyan;
            return GestureDetector(
              onTap: () => setState(() => selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: sel ? color.withOpacity(0.12) : _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? color : _border,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f,
                      style: TextStyle(
                        color: sel ? color : _muted,
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? color.withOpacity(0.2) : _border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_count(f)}',
                        style: TextStyle(
                          color: sel ? color : _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── BODY ────────────────────────────────────────────────
  Widget _body() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: _cyan));
    }
    if (error != null) return _errorView();

    final list = _filtered;
    if (list.isEmpty) {
      return _emptyView(
        selectedFilter == 'ALL'
            ? 'No vulnerabilities found ✅'
            : 'No $selectedFilter vulnerabilities',
        Icons.shield_outlined,
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        color: _cyan,
        backgroundColor: _card,
        onRefresh: _fetch,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final v = list[i];
            final severity = (v['severity'] ?? 'LOW').toString().toUpperCase();
            final package = v['package'] ?? 'Unknown Package';
            final fix = v['fix'] ?? 'No fix available';
            final cve = v['cve'] ?? 'CVE-${1234 + i}';
            final color = _color(severity);

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (i * 60).clamp(0, 600)),
              builder: (ctx, val, child) => Opacity(
                opacity: val,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - val)),
                  child: child,
                ),
              ),
              child: _vulnCard(
                severity: severity,
                package: package,
                fix: fix,
                cve: cve,
                color: color,
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── VULN CARD ───────────────────────────────────────────
  Widget _vulnCard({
    required String severity,
    required String package,
    required String fix,
    required String cve,
    required Color color,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(height: 3, color: color.withOpacity(0.7)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              package,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _badge(severity, color),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cve,
                        style: TextStyle(
                          color: color.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fix,
                        style: const TextStyle(color: _muted, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );

  Widget _emptyView(String msg, IconData icon) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _cyan.withOpacity(0.4), size: 60),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    ),
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: _red, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Failed to load vulnerabilities',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            error!,
            style: const TextStyle(color: _muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetch,
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    ),
  );
}
