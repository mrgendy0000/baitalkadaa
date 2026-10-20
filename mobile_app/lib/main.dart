import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BaytAlQanoonApp());
}

// -----------------------------------------------------------------------------
// التطبيق الرئيسي وثيم "بيت القانون"
// -----------------------------------------------------------------------------
class BaytAlQanoonApp extends StatelessWidget {
  const BaytAlQanoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بيت القانون | Bayt Al-Qanoon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Tajawal',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B1B3D),
          primary: const Color(0xFF0B1B3D),
          secondary: const Color(0xFFD97706),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1B3D),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: false,
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. الشاشة الافتتاحية (Splash Screen) بلوغو وهوية "بيت القانون"
// -----------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();

    // انتقال تلقائي بعد انتهاء العرض التقديمي
    _splashTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, __, ___) => const BaytAlQanoonHomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1B3D),
      body: Stack(
        children: [
          // خلفية بتدرج ملكي وأشكال إشعاعية
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD97706).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E40AF).withOpacity(0.12),
              ),
            ),
          ),

          Center(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // أيقونة اللوغو الفخمة
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD97706).withOpacity(0.35),
                                blurRadius: 35,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withOpacity(0.6),
                              width: 2.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF071228),
                                child: const Center(
                                  child: Icon(
                                    Icons.balance,
                                    size: 70,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // اسم المنظومة
                        const Text(
                          'بـيـت الـقـانـون',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'BAYT AL-QANOON LEGAL ENTERPRISE',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: const Text(
                            'المساعد الذكي الأول للمحامي في مصر • تجربة 15 يوماً',
                            style: TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // مؤشر التحميل الذهبي
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFFF59E0B),
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // تذييل الشاشة
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'مدعوم بدستور وقوانين وأحكام نقض جمهورية مصر العربية',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. الشاشة الرئيسية لمنظومة "بيت القانون" وتطبيقات المكتب الرقمي
// -----------------------------------------------------------------------------
class BaytAlQanoonHomeScreen extends StatefulWidget {
  const BaytAlQanoonHomeScreen({super.key});

  @override
  State<BaytAlQanoonHomeScreen> createState() => _BaytAlQanoonHomeScreenState();
}

class _BaytAlQanoonHomeScreenState extends State<BaytAlQanoonHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _birdAnimController;
  late Animation<double> _birdFloatAnimation;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // حركة العصفور المتحرك (Floating animation)
    _birdAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _birdFloatAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _birdAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _birdAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // فتح نافذة الدردشة مع عقل المساعد القضائي
  void _openFalconChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FalconChatModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // قائمة تطبيقات أودو القانونية الكاملة
    final List<Map<String, dynamic>> allApps = [
      {
        'id': 'cases',
        'title': 'القضايا والملفات',
        'sub': 'كانبان وإدارة الدعاوى',
        'icon': Icons.folder_shared_rounded,
        'color': const Color(0xFF0B1B3D),
        'accent': const Color(0xFF1E40AF),
        'badge': '5 نشطة',
        'page': const CasesManagementScreen(),
      },
      {
        'id': 'sessions',
        'title': 'رول الجلسات',
        'sub': 'أجندة المحاكم والقرارات',
        'icon': Icons.gavel_rounded,
        'color': const Color(0xFF065F46),
        'accent': const Color(0xFF10B981),
        'badge': '4 اليوم',
        'page': const CourtSessionsScreen(),
      },
      {
        'id': 'deadlines',
        'title': 'حاسبة المواعيد',
        'sub': 'استئناف ونقض م 18 مرافعات',
        'icon': Icons.hourglass_bottom_rounded,
        'color': const Color(0xFF1E3A8A),
        'accent': const Color(0xFF3B82F6),
        'badge': 'رسمية',
        'page': const ProceduralDeadlinesScreen(),
      },
      {
        'id': 'templates',
        'title': 'صيغ الدعاوي والعقود',
        'sub': 'خلع، إيجارات، جنح مباشرة',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF581C87),
        'accent': const Color(0xFF9333EA),
        'badge': '10+ صيغ',
        'page': const LegalTemplatesScreen(),
      },
      {
        'id': 'clients',
        'title': 'الموكلين والتوكيلات',
        'sub': 'سجل الشهر العقاري والموكلين',
        'icon': Icons.people_alt_rounded,
        'color': const Color(0xFF0E7490),
        'accent': const Color(0xFF06B6D4),
        'badge': '5 موكلين',
        'page': const ClientsPoaScreen(),
      },
      {
        'id': 'finance',
        'title': 'الخزينة والأتعاب',
        'sub': 'حسابات الدفعات والمصروفات',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF9A3412),
        'accent': const Color(0xFFEA580C),
        'badge': '225 ألف',
        'page': const LegalFinanceScreen(),
      },
      {
        'id': 'directory',
        'title': 'دليل المحاكم والنيابات',
        'sub': 'عناوين وأرقام الجمهورية',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFF166534),
        'accent': const Color(0xFF22C55E),
        'badge': 'محدث',
        'page': const CourtsDirectoryScreen(),
      },
      {
        'id': 'laws',
        'title': 'موسوعة الدستور والقوانين',
        'sub': 'عقوبات، مرافعات، نقض',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF831843),
        'accent': const Color(0xFFDB2777),
        'badge': '12 مادة',
        'page': const LawsEncyclopediaScreen(),
      },
      {
        'id': 'calculators',
        'title': 'حاسبة المواريث والرسوم',
        'sub': 'ق 77 لسنة 1943 والرسوم القضائية',
        'icon': Icons.calculate_rounded,
        'color': const Color(0xFFB45309),
        'accent': const Color(0xFFF59E0B),
        'badge': 'دقيقة',
        'page': const LegalCalculatorsScreen(),
      },
      {
        'id': 'memo',
        'title': 'لوحة الصياغة القضائية',
        'sub': 'محرر مذكرات الدفوع للبراءة',
        'icon': Icons.edit_document,
        'color': const Color(0xFF1E293B),
        'accent': const Color(0xFF475569),
        'badge': 'جاهزة',
        'page': const DraftingCanvasScreen(),
      },
    ];

    // تصفية التطبيقات وفق البحث
    final filteredApps = allApps.where((app) {
      if (_searchQuery.isEmpty) return true;
      return (app['title'] as String).contains(_searchQuery) ||
          (app['sub'] as String).contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.balance,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بـيـت الـقـانـون',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                Text(
                  'منظومة إدارة مكاتب المحاماة • بيت القانون',
                  style: TextStyle(fontSize: 9, color: Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'مستشار الذكاء الاصطناعي',
            icon: const Icon(Icons.psychology, color: Color(0xFFF59E0B)),
            onPressed: _openFalconChatSheet,
          ),
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تمت مزامنة بيانات بيت القانون بنجاح.'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Color(0xFF0B1B3D),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // بنر الهوية والترحيب
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1B3D), Color(0xFF1E3A8A)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B1B3D).withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                              child: const Text(
                                'مرحباً بك يا سيادة الأستاذ ⚖️',
                                style: TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'مكتبك الرقمي المتكامل',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'اضغط على العصفور المتحرك في اليمين للاستشارة الفورية باللهجة المصرية!',
                              style: TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // صورة مصغرة للعصفور المحامي
                      GestureDetector(
                        onTap: _openFalconChatSheet,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF59E0B),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/lawyer_bird.png',
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // شريط بحث تطبيقات أودو
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن تطبيق، قضية، صيغة، أو مادة قانونية...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF0B1B3D),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // عنوان شبكة التطبيقات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تطبيقات المنظومة القانونية',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B1B3D),
                      ),
                    ),
                    Text(
                      '${filteredApps.length} تطبيق',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // شبكة تطبيقات المكتب القانوني
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredApps.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, idx) {
                    final app = filteredApps[idx];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => app['page'] as Widget),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: (app['color'] as Color).withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // أيقونة التطبيق ثلاثية الأبعاد
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (app['color'] as Color).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    app['icon'] as IconData,
                                    color: app['color'] as Color,
                                    size: 24,
                                  ),
                                ),
                                // شارة الإشعار/العدد
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (app['accent'] as Color).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    app['badge'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: app['accent'] as Color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              app['title'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              app['sub'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // العصفور المتحرك بروب المحاماة في يمين الشاشة الرئيسية
          // (Floating Mascot wearing lawyer's robe)
          // -------------------------------------------------------------------
          Positioned(
            right: 16,
            bottom: 20,
            child: AnimatedBuilder(
              animation: _birdFloatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _birdFloatAnimation.value),
                  child: GestureDetector(
                    onTap: _openFalconChatSheet,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD97706).withOpacity(0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // صورة العصفور بالروب
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/lawyer_bird.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'المستشار صقر',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'بالنقض',
                                      style: TextStyle(
                                        color: Color(0xFF0B1B3D),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'اضغط للاستشارة المصرية 💬',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. عقل المساعد القضائي "المستشار صقر حورس" (Egyptian Dialect AI Chat)
// -----------------------------------------------------------------------------
class FalconChatModal extends StatefulWidget {
  const FalconChatModal({super.key});

  @override
  State<FalconChatModal> createState() => _FalconChatModalState();
}

class _FalconChatModalState extends State<FalconChatModal> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text':
          'يا مرحب بيك يا زميلي العزيز وسرورك على راسي! أنا المستشار صقر حورس، مستشارك في جيبك وفي ضهرك دائماً.\n'
          'اسألني بأي طريقة باللهجة المصرية في قضايا الجنايات، الجنح، الإيصالات، الخلع والأسرة، الإيجارات، أو أي دفع في الدستور المصري، وأنا هأصلك الدفوع وأجهزلك المذكرة فوراً!'
    }
  ];

  final List<String> _quickChips = [
    'وصل أمانة على بياض وضمان لمعاملة تجارية',
    'اتقبض عليه في كمين وتفتيش باطل بدون تلبس',
    'عايزة أرفع خلع وإنذار عرض مقدم الصداق',
    'طرد إيجار قديم وامتداد العقد للورثة',
    'ميعاد استئناف جنحة غيابي وحضوري اعتباري',
    'حصانة واستقلال مهنة المحاماة م 198 بالدستور',
    'جنحة مباشرة شيك بدون رصيد م 534 تجارة'
  ];

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': query});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final res = await http
          .post(
            Uri.parse('http://127.0.0.1:8000/api/chat/stream'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': query,
              'case_type': 'عام',
              'client_capacity': 'المحامي بالنقض',
              'court_circuit': 'محكمة النقض والاستئناف',
            }),
          )
          .timeout(const Duration(seconds: 4));

      String fullReply = '';
      final lines = res.body.split('\n');
      for (final line in lines) {
        if (line.startsWith('data:')) {
          final jsonStr = line.substring(5).trim();
          if (jsonStr.isNotEmpty) {
            try {
              final parsed = jsonDecode(jsonStr);
              if (parsed['token'] != null) {
                fullReply += parsed['token'];
              }
            } catch (_) {}
          }
        }
      }

      if (fullReply.isEmpty) {
        fullReply = _generateOfflineEgyptianResponse(query);
      }

      setState(() {
        _messages.add({'role': 'assistant', 'text': fullReply});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      // رد محلي ذكي فوري باللهجة المصرية في حال عدم اتصال الخادم
      final offlineReply = _generateOfflineEgyptianResponse(query);
      setState(() {
        _messages.add({'role': 'assistant', 'text': offlineReply});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // عقل احتياطي محلي ناطق باللهجة المصرية الأصيلة ومؤصل بالقانون المصري
  String _generateOfflineEgyptianResponse(String query) {
    final q = query.toLowerCase();
    if (q.contains('أمانة') || q.contains('امانة') || q.contains('إيصال') || q.contains('وصل') || q.contains('بياض')) {
      return 'يا هلا بيك يا زميلي العزيز.. في إيصال الأمانة ده ما تشيلش أي هم خالص!\n\n'
          '📌 الدفوع الجوهرية اللي هتسطرها قدام القاضي:\n'
          '1. انتفاء الركن المادي لجريمة خيانة الأمانة بركيزته الأساسية (ركن التسليم الفعلي للمال) طبقاً للمادة 341 عقوبات.\n'
          '2. الدفع بمدنية النزاع لكون الإيصال أداة ضمان لمعاملة تجارية وانحسار الحماية الجنائية.\n'
          '3. الطعن بالجهالة والتزوير صلباً وتاريخاً وطلب إحالة الورقة للطب الشرعي لبيان عدم المعاصرة.\n\n'
          '🏛️ قضاء محكمة النقض (طعن 9421 لسنة 76 ق): جريمة خيانة الأمانة لا تتكامل إلا بتسليم حقيقي وفعلي للمال بمقتضى أحد عقود الأمانة الخمسة.';
    } else if (q.contains('قبض') || q.contains('تفتيش') || q.contains('كمين') || q.contains('تلبس') || q.contains('ضابط')) {
      return 'يا فندم القضية دي كسبانة براءة بالضربة القاضية بإذن الله!\n\n'
          '📌 الدفوع الجوهرية:\n'
          '1. بطلان القبض والتفتيش وما تلاهما لانتفاء حالة التلبس (المادة 54 من الدستور والمادتين 30 و34 إجراءات جنائية).\n'
          '2. بطلان الاستيقاف وتحوله لاحتجاز غير مشروع لعدم وجود مظاهر ريب وتشكك تسوغ تقييد الحرية.\n'
          '3. بطلان الدليل المستمد من القبض الباطل لأن ما بُني على باطل فهو باطل، والتحريات مكتبية ولا تعد دليلاً.\n\n'
          '🏛️ قضاء النقض (طعن 18451 لسنة 88 ق): التلبس يستوجب مشاهدة الجريمة بحاسة من الحواس وبطلان القبض يوجب بطلان سائر الأدلة.';
    } else if (q.contains('خلع') || q.contains('صداق') || q.contains('مهر') || q.contains('طلاق')) {
      return 'من عيوني يا زميلي العزيز.. إجراءات الخلع في القانون المصري محكمة جداً:\n\n'
          '📌 الخطوات والدفوع:\n'
          '1. إعلان الزوج رسمياً بإنذار عرض مقدم الصداق الثابت بالوثيقة على يد محضر وإيداعه خزينة المحكمة.\n'
          '2. التمسك بنص المادة 20 من القانون رقم 1 لسنة 2000 بإقرار الزوجة صراحة بالتنازل عن المؤخر والنفقة.\n'
          '3. التمسك بأن حكم الخلع الصادر يقع طلقة بائنة وهو حكم نهائي غير قابل للطعن بأي طريق من طرق الطعن.';
    } else if (q.contains('دستور') || q.contains('محاماة') || q.contains('198') || q.contains('حصانة')) {
      return 'الله يفتح عليك يا زميلي لسؤالك عن أسمى نص للمحامين في مصر!\n\n'
          'المادة 198 من دستور مصر 2014 وضعت المحاماة في مكانتها الرفيعة:\n'
          '«المحاماة مهنة حرة، تشارك السلطة القضائية في تحقيق العدالة، وسيادة القانون، وكفالة حق الدفاع، ويمارسها المحامي استقلالاً، ويتمتع المحامون بجميع الضمانات والحماية المقررة لهم أثناء تأديتهم لرسالتهم أمام المحاكم وجهات التحقيق والاستدلال».\n'
          'أنت شريك المنصة وحصانتك مصونة دستورياً!';
    } else {
      return 'أهلاً بيك يا زميلي العزيز.. معاك المستشار صقر حورس، مستشارك في جيبك وفي ضهرك دائماً!\n\n'
          'بص يا فندم، الواقعة دي لازم نشتغل عليها على ثلاث محاور:\n'
          '1. الدفوع الشكلية الخاصة بالاختصاص المحلي والنوعي والمواعيد القانونية (المادة 18 مرافعات).\n'
          '2. تفنيد أدلة الخصم استناداً لقاعدة البينة على من ادعى (المادة 1 من قانون الإثبات).\n'
          '3. التأصيل بأحكام محكمة النقض ونصوص القانون المدني أو الجنائي.\n\n'
          'جاهز أصيغلك مسودة المذكرة فوراً وننقلها للوحة الصياغة!';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // مقبض السحب والهيدر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0B1B3D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/lawyer_bird.png',
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'المستشار صقر حورس',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              '• نقض ودستور مصري',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'متحدث ومستشار باللهجة المصرية الأصيلة',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // شرائح الأسئلة السريعة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _quickChips.map((chip) {
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ActionChip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    label: Text(
                      chip,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF0B1B3D)),
                    ),
                    onPressed: () => _sendMessage(chip),
                  ),
                );
              }).toList(),
            ),
          ),

          // الرسائل
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final m = _messages[idx];
                final isAssistant = m['role'] == 'assistant';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        isAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
                    children: [
                      if (isAssistant) ...[
                        ClipOval(
                          child: Image.asset(
                            'assets/images/lawyer_bird.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isAssistant ? Colors.white : const Color(0xFF0B1B3D),
                            borderRadius: BorderRadius.circular(18),
                            border: isAssistant
                                ? Border.all(color: Colors.grey.shade200)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                m['text'] ?? '',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isAssistant ? const Color(0xFF1E293B) : Colors.white,
                                  height: 1.5,
                                ),
                              ),
                              if (isAssistant && idx > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(
                                          ClipboardData(text: m['text'] ?? ''),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('تم نسخ الدفوع القانونية'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.copy, size: 12, color: Colors.grey),
                                            SizedBox(width: 4),
                                            Text('نسخ الدفوع', style: TextStyle(fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: LinearProgressIndicator(color: Color(0xFF0B1B3D)),
            ),

          // حقل الإدخال السفلي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'اطرح الواقعة أو القضية باللهجة المصرية...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0B1B3D),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. شاشات تطبيقات المنظومة القانونية
// -----------------------------------------------------------------------------

// أ. شاشة القضايا والملفات
class CasesManagementScreen extends StatelessWidget {
  const CasesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cases = [
      {
        'num': '1425 لسنة 2026 جنح قصر النيل',
        'court': 'جنح مستأنف قصر النيل',
        'client': 'مروان عصام عبد الرحمن',
        'type': 'خيانة أمانة (إيصال أمانة)',
        'stage': 'متداولة بالجلسات',
        'date': '2026-04-26',
        'fee': '45,000 ج',
      },
      {
        'num': '5521 لسنة 2025 مدني شمال القاهرة',
        'court': 'شمال القاهرة الابتدائية',
        'client': 'مؤسسة النيل للتجارة',
        'type': 'تعويض عن إخلال عقدي',
        'stage': 'قيد فحص الخبراء',
        'date': '2026-05-10',
        'fee': '80,000 ج',
      },
      {
        'num': '319 لسنة 2026 أسرة مصر الجديدة',
        'court': 'أسرة مصر الجديدة',
        'client': 'سارة إبراهيم الدسوقي',
        'type': 'تطليق خلعاً ونفقة',
        'stage': 'محجوزة للحكم',
        'date': '2026-04-22',
        'fee': '35,000 ج',
      },
      {
        'num': '912 لسنة 2024 مدني كلي الجيزة',
        'court': 'محكمة الجيزة الابتدائية',
        'client': 'الحاج فاروق عبد العظيم',
        'type': 'طرد للغصب وانتهاء مدة',
        'stage': 'إجراءات التنفيذ الجبري',
        'date': '2026-04-30',
        'fee': '60,000 ج',
      },
      {
        'num': '7812 لسنة 2026 جنايات القاهرة',
        'court': 'جنايات القاهرة الجديدة',
        'client': 'شريف عادل المنشاوي',
        'type': 'حيازة سلاح ومخدرات',
        'stage': 'متداولة بالجلسات',
        'date': '2026-05-18',
        'fee': '120,000 ج',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة القضايا والملفات')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: cases.length,
        itemBuilder: (context, idx) {
          final c = cases[idx];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c['num'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0B1B3D),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c['stage'],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Text('المحكمة: ${c['court']}', style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 3),
                  Text('الموكل: ${c['client']}', style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 3),
                  Text('الموضوع: ${c['type']}', style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الجلسة القادمة: ${c['date']}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      Text(
                        'الأتعاب: ${c['fee']}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ب. شاشة رول الجلسات والأجندة
class CourtSessionsScreen extends StatelessWidget {
  const CourtSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> sessions = [
      {
        'roll': '14',
        'case': '1425 لسنة 2026 جنح قصر النيل',
        'court': 'جنح مستأنف قصر النيل',
        'date': '2026-04-26 (الأحد)',
        'decision': 'تأجيل لتقديم أصل الإيصال والمذكرات',
        'action': 'إيداع مذكرة الدفاع والطعن بالتزوير صلب وتاريخ',
      },
      {
        'roll': '22',
        'case': '319 لسنة 2026 أسرة مصر الجديدة',
        'court': 'محكمة أسرة مصر الجديدة',
        'date': '2026-04-22 (الأربعاء)',
        'decision': 'حجز الدعوى للحكم',
        'action': 'حضور جلسة النطق بالحكم واستلام الصورة التنفيذية',
      },
      {
        'roll': '7',
        'case': '5521 لسنة 2025 مدني شمال القاهرة',
        'court': 'شمال القاهرة الابتدائية',
        'date': '2026-05-10 (الأحد)',
        'decision': 'تأجيل لإيداع تقرير خبير وزارة العدل',
        'action': 'حضور أمام مكتب الخبراء وتقديم المستندات',
      },
      {
        'roll': '5',
        'case': '7812 لسنة 2026 جنايات القاهرة',
        'court': 'جنايات القاهرة (التجمع الخامس)',
        'date': '2026-05-18 (الإثنين)',
        'decision': 'سماع أقوال ضابط الواقعة',
        'action': 'مناقشة الضابط في التلبس وبطلان الاستيقاف',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('رول الجلسات والأجندة القضائية')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sessions.length,
        itemBuilder: (context, idx) {
          final s = sessions[idx];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1B3D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '#${s['roll']}',
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['case']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${s['court']} • ${s['date']}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'القرار السابق: ${s['decision']}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'المطلوب بالجلسة: ${s['action']}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)),
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
        },
      ),
    );
  }
}

// ج. شاشة صيغ الدعاوي والعقود المصرية
class LegalTemplatesScreen extends StatefulWidget {
  const LegalTemplatesScreen({super.key});

  @override
  State<LegalTemplatesScreen> createState() => _LegalTemplatesScreenState();
}

class _LegalTemplatesScreenState extends State<LegalTemplatesScreen> {
  String _selectedCat = 'الكل';

  final List<Map<String, String>> _templates = [
    {
      'title': 'صحيفة دعوى تطليق خلعاً وإنذار عرض مقدم الصداق',
      'cat': 'أحوال شخصية',
      'law': 'المادة 20 من القانون رقم 1 لسنة 2000',
      'preview':
          'عريضة دعوى خلع كاملة مع إقرار التنازل عن مؤخر الصداق والنفقة وإنذار عرض مقدم الصداق على يد محضر رسمي.',
    },
    {
      'title': 'مذكرة دفاع في خيانة أمانة (انتفاء ركن التسليم والطعن بالتزوير)',
      'cat': 'جنائي',
      'law': 'المادة 341 عقوبات وقضاء النقض',
      'preview':
          'مذكرة دفوع جوهرية ببراءة المتهم ومدنية النزاع لكون إيصال الأمانة سلم كضمان مع طلب إحالته لمصلحة الطب الشرعي.',
    },
    {
      'title': 'صحيفة دعوى طرد للغصب وانتهاء علاقة إيجارية',
      'cat': 'مدني وإيجارات',
      'law': 'القانون 4 لسنة 1996 والقانون المدني',
      'preview':
          'دعوى طرد لانتهاء مدة العقد وعدم الرغبة في التجديد والمطالبة بريع المثل والتعويض الاتفاقي.',
    },
    {
      'title': 'جنحة مباشرة شيك بدون رصيد والادعاء مدنياً',
      'cat': 'تجاري وجنائي',
      'law': 'المادة 534 من قانون التجارة رقم 17 لسنة 1999',
      'preview':
          'عريضة جنحة مباشرة بالتعويض المؤقت 15001 ج مع إعلان وكيل النيابة والساحب لجلسة أمام محكمة الجنح.',
    },
    {
      'title': 'عقد إيجار شقة سكنية محدد المدة مشمول بالصيغة التنفيذية',
      'cat': 'عقود وتوثيق',
      'law': 'القانون 4 لسنة 1996 وتعديلاته بالشهر العقاري',
      'preview':
          'صيغة عقد إيجار حديث مجهز للتذييل بالصيغة التنفيذية لتمكين المالك من الإخلاء الفوري عند انتهاء المدة.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCat == 'الكل'
        ? _templates
        : _templates.where((t) => t['cat'] == _selectedCat).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('بنك الصيغ والعقود القضائية')),
      body: Column(
        children: [
          // فلاتر التصنيف
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['الكل', 'أحوال شخصية', 'جنائي', 'مدني وإيجارات', 'تجاري وجنائي', 'عقود وتوثيق']
                  .map((cat) {
                final isSelected = _selectedCat == cat;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat, style: const TextStyle(fontSize: 11)),
                    selectedColor: const Color(0xFF0B1B3D),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF0B1B3D),
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => _selectedCat = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (context, idx) {
                final t = filtered[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                t['title']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0B1B3D),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF581C87).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t['cat']!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF581C87),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'السند القانوني: ${t['law']}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t['preview']!,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0B1B3D),
                                side: const BorderSide(color: Color(0xFF0B1B3D)),
                              ),
                              icon: const Icon(Icons.copy, size: 14),
                              label: const Text('نسخ الصيغة', style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: t['preview']!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ الصيغة القانونية'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// د. شاشة حاسبة المواعيد القضائية (م 18 مرافعات)
class ProceduralDeadlinesScreen extends StatefulWidget {
  const ProceduralDeadlinesScreen({super.key});

  @override
  State<ProceduralDeadlinesScreen> createState() =>
      _ProceduralDeadlinesScreenState();
}

class _ProceduralDeadlinesScreenState extends State<ProceduralDeadlinesScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'civil_appeal';
  Map<String, dynamic>? _result;

  void _calculate() {
    int days = 40;
    String basis = 'المادة 227 مرافعات';
    String name = 'استئناف مدني عادي';

    if (_selectedType == 'misdemeanor_appeal') {
      days = 10;
      basis = 'المادة 406 إجراءات جنائية';
      name = 'استئناف جنح ومخالفات';
    } else if (_selectedType == 'urgent_appeal') {
      days = 15;
      basis = 'المادة 227 فقرة 2 مرافعات';
      name = 'استئناف مستعجل';
    } else if (_selectedType == 'cassation') {
      days = 60;
      basis = 'المادة 34 من قانون 57 لسنة 1959';
      name = 'الطعن بالنقض';
    } else if (_selectedType == 'opposition') {
      days = 10;
      basis = 'المادة 398 إجراءات جنائية';
      name = 'المعارضة في جنحة غيابية';
    }

    final firstCounted = _selectedDate.add(const Duration(days: 1));
    DateTime nominalLast = _selectedDate.add(Duration(days: days));

    // امتداد العطلات (الجمعة 5، السبت 6 في Dart DateTime: Monday=1, Friday=5, Saturday=6, Sunday=7)
    DateTime finalDate = nominalLast;
    bool wasExtended = false;

    while (finalDate.weekday == DateTime.friday || finalDate.weekday == DateTime.saturday) {
      wasExtended = true;
      finalDate = finalDate.add(const Duration(days: 1));
    }

    setState(() {
      _result = {
        'name': name,
        'days': days,
        'basis': basis,
        'firstCounted': '${firstCounted.year}-${firstCounted.month.toString().padLeft(2, '0')}-${firstCounted.day.toString().padLeft(2, '0')}',
        'nominal': '${nominalLast.year}-${nominalLast.month.toString().padLeft(2, '0')}-${nominalLast.day.toString().padLeft(2, '0')}',
        'final': '${finalDate.year}-${finalDate.month.toString().padLeft(2, '0')}-${finalDate.day.toString().padLeft(2, '0')}',
        'extended': wasExtended,
      };
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة المواعيد القضائية الرسمية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('نوع الطعن أو الميعاد الإجرائي:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'civil_appeal',
                          child: Text('استئناف مدني عادي (40 يوماً)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'misdemeanor_appeal',
                          child: Text('استئناف جنح ومخالفات (10 أيام)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'urgent_appeal',
                          child: Text('استئناف مستعجل (15 يوماً)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'cassation',
                          child: Text('الطعن بالنقض (60 يوماً)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'opposition',
                          child: Text('معارضة جنحة غيابية (10 أيام)', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          _selectedType = val;
                          _calculate();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('تاريخ صدور الحكم أو إعلانه:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      title: Text(
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.calendar_month, color: Color(0xFF0B1B3D)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                          _calculate();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B1B3D), Color(0xFF1E3A8A)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B1B3D).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _result!['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_result!['days']} يوماً',
                            style: const TextStyle(
                              color: Color(0xFF0B1B3D),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'السند القانوني: ${_result!['basis']}',
                      style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11),
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    _buildCalcRow('أول يوم يُحسب في الميعاد:', _result!['firstCounted']),
                    const SizedBox(height: 8),
                    _buildCalcRow('نهاية الميعاد الاسمية:', _result!['nominal']),
                    const SizedBox(height: 8),
                    _buildCalcRow(
                      'آخر موعد رسمي لسقوط الحق:',
                      _result!['final'],
                      isHighlighted: true,
                    ),
                    if (_result!['extended'] == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⚡ تنبيه: امتد الميعاد بقوة القانون عملاً بنص المادة 18 مرافعات لمصادفة آخر يوم عطلة المحاكم الرسمية (الجمعة أو السبت).',
                          style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlighted ? const Color(0xFFF59E0B) : Colors.white70,
            fontSize: isHighlighted ? 12 : 11,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? const Color(0xFFF59E0B) : Colors.white,
            fontSize: isHighlighted ? 15 : 12,
            fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// هـ. شاشة دليل المحاكم والنيابات بجمهورية مصر العربية
class CourtsDirectoryScreen extends StatelessWidget {
  const CourtsDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> directory = [
      {
        'name': 'دار القضاء العالي (محكمة النقض واستئناف القاهرة)',
        'gov': 'القاهرة',
        'addr': 'شارع 26 يوليو - وسط البلد - رمسيس',
        'phone': '0225781190',
        'type': 'نقض واستئناف والنائب العام',
      },
      {
        'name': 'مجمع محاكم التجمع الخامس (القاهرة الجديدة)',
        'gov': 'القاهرة',
        'addr': 'شارع التسعين الجنوبي - التجمع الخامس',
        'phone': '0228105422',
        'type': 'ابتدائية وجنايات وأسرة',
      },
      {
        'name': 'مجمع محاكم الجلاء (جنوب القاهرة الابتدائية)',
        'gov': 'القاهرة',
        'addr': 'شارع الجلاء - رمسيس',
        'phone': '0225754820',
        'type': 'ابتدائية وجزئية ونيابات',
      },
      {
        'name': 'مجمع محاكم العباسية (شمال القاهرة الابتدائية)',
        'gov': 'القاهرة',
        'addr': 'ميدان العباسية - بجوار محطة المترو',
        'phone': '0226841203',
        'type': 'جنايات ومدني وأسرة',
      },
      {
        'name': 'مجمع محاكم الجيزة (شارع السودان)',
        'gov': 'الجيزة',
        'addr': 'شارع السودان - تقاطع فيصل وميدان الجيزة',
        'phone': '0237748520',
        'type': 'ابتدائية وجزئية ومدني وأسرة',
      },
      {
        'name': 'مجمع محاكم المنشية والسيالة (الإسكندرية)',
        'gov': 'الإسكندرية',
        'addr': 'ميدان المنشية - أمام تمثال محمد علي',
        'phone': '034871230',
        'type': 'استئناف عالي وابتدائية',
      },
      {
        'name': 'مكتب توثيق الأهرام النموذجي المميكن',
        'gov': 'الجيزة',
        'addr': 'شارع الهرم - مجمع المصالح الحكومية',
        'phone': '0235841029',
        'type': 'شهر عقاري وتوثيق توكيلات',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('دليل المحاكم والنيابات والشهر العقاري')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: directory.length,
        itemBuilder: (context, idx) {
          final c = directory[idx];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          c['name']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0B1B3D),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF166534).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c['gov']!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('العنوان: ${c['addr']}', style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الهاتف: ${c['phone']}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      Text(
                        c['type']!,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// و. شاشة الموكلين والتوكيلات
class ClientsPoaScreen extends StatelessWidget {
  const ClientsPoaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> clients = [
      {
        'name': 'مروان عصام عبد الرحمن',
        'nid': '28804150102574',
        'phone': '01098765432',
        'poa': '3824 / ب لسنة 2026 توثيق الأهرام',
        'type': 'توكيل رسمي عام قضايا وبنوك',
      },
      {
        'name': 'مؤسسة النيل للتجارة والمقاولات',
        'nid': '100458921 (سجل تجاري)',
        'phone': '01234567890',
        'poa': '9124 لسنة 2025 توثيق الاستثمار',
        'type': 'توكيل شركات وتفويض إدارة',
      },
      {
        'name': 'سارة إبراهيم الدسوقي',
        'nid': '29508120104822',
        'phone': '01122334455',
        'poa': '1540 لسنة 2026 توثيق مصر الجديدة',
        'type': 'توكيل قضايا وأحوال شخصية',
      },
      {
        'name': 'الحاج فاروق عبد العظيم',
        'nid': '25203110103215',
        'phone': '01001122334',
        'poa': '7812 لسنة 2024 توثيق الجيزة',
        'type': 'توكيل رسمي عام قضايا',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الموكلين وأرقام التوكيلات')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: clients.length,
        itemBuilder: (context, idx) {
          final cl = clients[idx];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cl['name']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0B1B3D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('الرقم القومي: ${cl['nid']}', style: const TextStyle(fontSize: 11)),
                  Text('الهاتف: ${cl['phone']}', style: const TextStyle(fontSize: 11)),
                  const Divider(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E7490).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'التوكيل: ${cl['poa']}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0E7490),
                          ),
                        ),
                        Text(
                          cl['type']!,
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ز. شاشة الخزينة والأتعاب
class LegalFinanceScreen extends StatelessWidget {
  const LegalFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الخزينة وحسابات الأتعاب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'إجمالي الأتعاب المتعاقد عليها',
                    '225,000 ج',
                    const Color(0xFF0B1B3D),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    'المقبوضات الفعلية',
                    '155,000 ج',
                    const Color(0xFF065F46),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildMetricTile('المتبقي طرف الموكلين', '70,000 ج', const Color(0xFF9A3412)),
            const SizedBox(height: 20),
            const Row(
              children: [
                Text(
                  'سجل المعاملات والسندات الأخيرة',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTransactionTile(
              'مروان عصام عبد الرحمن',
              'دفعة أتعاب مرافعة وصياغة مذكرة',
              '+15,000 ج',
              '2026-04-18',
              isIncome: true,
            ),
            _buildTransactionTile(
              'مؤسسة النيل للمقاولات',
              'دفعة مقدم أتعاب الدعوى المدنية (إنستاباي)',
              '+20,000 ج',
              '2026-04-15',
              isIncome: true,
            ),
            _buildTransactionTile(
              'مصروفات قضائية وخزينة المحكمة',
              'سداد رسوم إيداع واستخراج صور رسمية',
              '-3,500 ج',
              '2026-04-14',
              isIncome: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    String party,
    String desc,
    String amount,
    String date, {
    required bool isIncome,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
            size: 18,
          ),
        ),
        title: Text(party, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Text('$desc • $date', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        trailing: Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green.shade800 : Colors.red.shade800,
          ),
        ),
      ),
    );
  }
}

// ح. شاشة موسوعة الدستور والقوانين المصرية
class LawsEncyclopediaScreen extends StatelessWidget {
  const LawsEncyclopediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> laws = [
      {
        'title': 'المادة 54 من الدستور المصري 2014 المعدل',
        'head': 'حرمة الحرية الشخصية وبطلان القبض بدون إذن أو تلبس',
        'text':
            'الحرية الشخصية حق طبيعي، وهي مصونة لا تُمس، وفيما عدا حالة التلبس، لا يجوز القبض على أحد، أو تفتيشه، أو حبسه، أو تقييد حريته بأي قيد إلا بأمر قضائي مسبب يستلزمه التحقيق.',
      },
      {
        'title': 'المادة 198 من الدستور المصري 2014 المعدل',
        'head': 'استقلال وحصانة وضمانات مهنة المحاماة',
        'text':
            'المحاماة مهنة حرة، تشارك السلطة القضائية في تحقيق العدالة، وسيادة القانون، وكفالة حق الدفاع، ويمارسها المحامي استقلالاً، ويتمتع المحامون جميعاً أثناء تأديتهم حق الدفاع بالضمانات والحماية.',
      },
      {
        'title': 'المادة 341 من قانون العقوبات رقم 58 لسنة 1937',
        'head': 'جريمة خيانة الأمانة وعقود الأمانة الخمسة',
        'text':
            'كل من اختلس أو استعمل أو بدد مبالغ أو أمتعة أو بضائع أو نقوداً أو كتابات وكانت لم تسلم له إلا على وجه الوديعة أو الإجارة أو عارية الاستعمال أو الرهن أو الوكالة يحكم عليه بالحبس.',
      },
      {
        'title': 'المادة 30 من قانون الإجراءات الجنائية رقم 150 لسنة 1950',
        'head': 'حالات التلبس بالجريمة على سبيل الحصر',
        'text':
            'تكون الجريمة متلبساً بها حال ارتكابها أو عقب ارتكابها ببرهة يسيرة، أو إذا تبع المجني عليه مرتكبها أو تبعته العامة مع الصياح إثر وقوعها.',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('موسوعة الدستور والقوانين')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: laws.length,
        itemBuilder: (context, idx) {
          final l = laws[idx];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l['title']!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l['head']!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0B1B3D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l['text']!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade800, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ط. شاشة حاسبة المواريث والرسوم
class LegalCalculatorsScreen extends StatefulWidget {
  const LegalCalculatorsScreen({super.key});

  @override
  State<LegalCalculatorsScreen> createState() => _LegalCalculatorsScreenState();
}

class _LegalCalculatorsScreenState extends State<LegalCalculatorsScreen> {
  double _claimAmount = 100000;
  double _relativeFee = 5000;
  double _fundFee = 1250;
  double _totalFees = 6400;

  void _recalc(double val) {
    setState(() {
      _claimAmount = val;
      _relativeFee = val * 0.05;
      _fundFee = _relativeFee * 0.25;
      _totalFees = _relativeFee + _fundFee + 150;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة الرسوم والمواريث')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('حاسبة الرسوم القضائية والدمغات (تقديرية):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  Text('قيمة المطالبة في الدعوى: ${_claimAmount.toInt()} جنيه'),
                  Slider(
                    value: _claimAmount,
                    min: 5000,
                    max: 1000000,
                    divisions: 100,
                    activeColor: const Color(0xFF0B1B3D),
                    onChanged: _recalc,
                  ),
                  const Divider(),
                  _buildRow('الرسم النسبي المقدر (5%):', '${_relativeFee.toInt()} ج'),
                  const SizedBox(height: 6),
                  _buildRow('صندوق الخدمات القضائية (25% من النسبي):', '${_fundFee.toInt()} ج'),
                  const SizedBox(height: 6),
                  _buildRow('دمغة المحاماة ورسوم النقابة:', '150 ج'),
                  const Divider(),
                  _buildRow('إجمالي الرسوم المتوقعة عند القيد:', '${_totalFees.toInt()} ج',
                      isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('حاسبة المواريث الشرعية (قانون 77 لسنة 1943):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 8),
                  Text(
                    'تعتمد المنظومة على الفروض المقدرة بالقرآن الكريم وحجب الورثة والعصبات:\n'
                    '• الزوج: النصف لعدم الفرع الوارث، والربع مع الفرع الوارث.\n'
                    '• الزوجة: الربع لعدم الفرع الوارث، والثمن مع الفرع الوارث.\n'
                    '• الأب والأم: السدس لكل منهما مع وجود فرع وارث مذكر.\n'
                    '• الأولاد: للذكر مثل حظ الأنثيين عصبة بالغير.',
                    style: TextStyle(fontSize: 11, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String val, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: isBold ? 14 : 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? const Color(0xFFD97706) : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ي. شاشة لوحة الصياغة القضائية
class DraftingCanvasScreen extends StatelessWidget {
  const DraftingCanvasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الصياغة القضائية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'محكمة جنح مستأنف قصر النيل والدقي',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const Center(
                child: Text(
                  'الدائرة الجنائية المستأنفة',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'مـذكـرة بـدفـاع',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Divider(height: 24),
              const Text(
                'الدفوع الجوهرية المؤصلة بقضاء محكمة النقض والدستور المصري:\n\n'
                'أولاً: الدفع ببطلان القبض والتفتيش لانتفاء حالة التلبس استناداً للمادة 54 من الدستور والمادتين 30 و34 إجراءات جنائية.\n\n'
                'ثانياً: الدفع بانتفاء ركن التسليم الحقيقي في إيصال الأمانة ومدنية النزاع سنداً للمادة 341 عقوبات.\n\n'
                'ثالثاً: الطعن بالجهالة والتزوير صلباً وتاريخاً وإحالة الورقة للطب الشرعي قسم أبحاث التزييف والتزوير لبيان عدم المعاصرة.',
                style: TextStyle(fontSize: 12, height: 1.6),
              ),
              const Divider(height: 24),
              const Text(
                'الطلبات:\nيلتمس الدفاع الحكم أصلياً ببراءة المتهم من التهم المنسوبة إليه.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
