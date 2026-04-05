// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart'; // adjust path if needed

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  final String repoId = Get.arguments ?? '';

  List<dynamic> alerts = [];
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
      final list = await ApiService.getAlerts(repoId);
      setState(() {
        alerts = list;
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
    if (selectedFilter == 'ALL') return alerts;
    return alerts
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

  IconData _icon(String s) {
    switch (s.toUpperCase()) {
      case 'HIGH':
        return Icons.crisis_alert_rounded;
      case 'MEDIUM':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  int _count(String f) => f == 'ALL'
      ? alerts.length
      : alerts
            .where((v) => (v['severity'] ?? '').toString().toUpperCase() == f)
            .length;

  int get _highCount => _count('HIGH');

  // ─── BUILD ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            if (!isLoading && error == null && alerts.isNotEmpty) _banner(),
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
                  'Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  '${alerts.length} active alert${alerts.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          // critical badge
          if (_highCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _red.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_highCount Critical',
                    style: const TextStyle(
                      color: _red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
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

  // ─── BANNER ──────────────────────────────────────────────
  Widget _banner() => Container(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_red.withOpacity(0.12), _orange.withOpacity(0.06)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _red.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: _red,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${alerts.length} Security Alert${alerts.length == 1 ? '' : 's'} Detected',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _highCount > 0
                    ? '$_highCount critical require immediate attention'
                    : 'Review and remediate open alerts',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          alerts.length.toString(),
          style: const TextStyle(
            color: _red,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
            ? 'No active alerts ✅'
            : 'No $selectedFilter alerts',
        Icons.notifications_off_outlined,
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
            // flexible field mapping
            final package = v['package'] ?? v['title'] ?? 'Unknown';
            final fix =
                v['fix'] ?? v['description'] ?? v['message'] ?? 'No details';
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
              child: _alertCard(
                severity: severity,
                package: package,
                fix: fix,
                color: color,
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── ALERT CARD ──────────────────────────────────────────
  Widget _alertCard({
    required String severity,
    required String package,
    required String fix,
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
          Container(height: 3, color: color.withOpacity(0.6)),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon(severity), color: color, size: 22),
            ),
            title: Text(
              package,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                fix,
                style: const TextStyle(color: _muted, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: color.withOpacity(0.35)),
              ),
              child: Text(
                severity,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _emptyView(String msg, IconData icon) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _cyan.withOpacity(0.4), size: 60),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 6),
        const Text(
          'Your repository looks secure',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
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
            'Failed to load alerts',
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
