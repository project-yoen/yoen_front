import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/model/user_response.dart';
import 'package:yoen_front/data/notifier/user_notifier.dart';

import '../data/dialog/single_day_picker_dialog.dart';
import '../data/dialog/universal_date_picker_dialog.dart';

/// ===============================
/// 0) 개인정보 조회 화면 (진입점)
/// ===============================
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(userNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('내 개인정보'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: '수정',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await showUserEditDialog(
                  context,
                  ref,
                  onSaved: () => ref.invalidate(userNotifierProvider),
                );
              },
            ),
          ],
        ),
        backgroundColor: isDark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF5F5F5),
        body: SafeArea(
          child: asyncUser.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('정보를 불러오지 못했습니다.\n$e', textAlign: TextAlign.center),
            ),
            data: (user) {
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(userNotifierProvider),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 0,
                      color: isDark
                          ? Theme.of(context).colorScheme.surface
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '기본 정보',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _ViewRow(label: '이름', value: user?.name ?? '-'),
                            const Divider(height: 24),
                            _ViewRow(
                              label: '닉네임',
                              value: user?.nickname ?? '-',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      color: isDark
                          ? Theme.of(context).colorScheme.surface
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '프로필 상세',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _ViewRow(
                              label: '성별',
                              value: _genderKo(user?.gender),
                            ),
                            const Divider(height: 24),
                            _ViewRow(
                              label: '생일',
                              value: _fmtDate(user?.birthday),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('수정'),
                      onPressed: () async {
                        await showUserEditDialog(
                          context,
                          ref,
                          onSaved: () => ref.invalidate(userNotifierProvider),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static String _genderKo(String? code) {
    switch (code) {
      case 'MALE':
        return '남성';
      case 'FEMALE':
        return '여성';
      case 'OTHERS':
        return '기타';
      default:
        return '-';
    }
  }

  static String _fmtDate(String? yyyyMMdd) {
    if (yyyyMMdd == null) return '-';
    try {
      final dt = DateTime.parse(yyyyMMdd);
      return DateFormat('yyyy년 MM월 dd일').format(dt);
    } catch (_) {
      return yyyyMMdd;
    }
  }
}

class _ViewRow extends StatelessWidget {
  const _ViewRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: t.bodyMedium)),
      ],
    );
  }
}

/// ===========================================
/// 1) 편집 다이얼로그를 여는 헬퍼 (+ 저장 후 콜백)
/// ===========================================
Future<void> showUserEditDialog(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onSaved,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent, // 외곽 투명
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500, // 웹/태블릿에서 폭 제한
              minWidth: 280,
            ),
            child: Material(
              color: isDark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.white,
              elevation: 6,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: UserEditDialog(onSaved: onSaved),
            ),
          ),
        ),
      );
    },
  );
}

/// ===========================================
/// 2) 수정 다이얼로그
/// ===========================================
class UserEditDialog extends ConsumerStatefulWidget {
  const UserEditDialog({super.key, this.onSaved});
  final VoidCallback? onSaved;

  @override
  ConsumerState<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends ConsumerState<UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  DateTime? _selectedBirthday;
  String _selectedGenderKo = '남성';

  final genderMap = const {'MALE': '남성', 'FEMALE': '여성', 'OTHERS': '기타'};
  final reverseGenderMap = const {'남성': 'MALE', '여성': 'FEMALE', '기타': 'OTHERS'};

  @override
  void initState() {
    super.initState();
    final user = ref.read(userNotifierProvider).value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _nicknameController = TextEditingController(text: user?.nickname ?? '');
    _selectedGenderKo = genderMap[user?.gender] ?? '남성';
    _selectedBirthday =
        (user?.birthday != null ? DateTime.tryParse(user!.birthday!) : null) ??
        DateTime(2000, 1, 1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday(BuildContext context) async {
    // 생일 범위: 1900-01-01 ~ 오늘
    final first = DateTime(1900, 1, 1);
    final last = DateTime.now();
    final initial = _selectedBirthday == null
        ? DateTime(2000, 1, 1)
        : _selectedBirthday!.isBefore(first)
        ? first
        : _selectedBirthday!.isAfter(last)
        ? last
        : _selectedBirthday!;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => UniversalDatePickerDialog.single(
        minDate: DateTime(1900, 1, 1),
        maxDate: DateTime.now(),
        initialDate: _selectedBirthday ?? DateTime(2000, 1, 1),
      ),
    );

    if (picked != null) {
      setState(() => _selectedBirthday = picked);
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label, {
    IconData? icon,
    String? hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9F9F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(), // unfocus
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: AppBar(
            title: const Text('프로필 수정'),
            centerTitle: true,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: '닫기',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 기본 정보
                Card(
                  elevation: 0,
                  color: isDark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('기본 정보', style: textTheme.titleMedium),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            context,
                            '이름',
                            icon: Icons.person_outline,
                            hint: '실명',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? '이름을 입력하세요'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nicknameController,
                          textInputAction: TextInputAction.done,
                          decoration: _inputDecoration(
                            context,
                            '닉네임',
                            icon: Icons.tag,
                            hint: '프로필 표시명',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? '닉네임을 입력하세요'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 상세
                Card(
                  elevation: 0,
                  color: isDark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('프로필 상세', style: textTheme.titleMedium),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('성별', style: textTheme.bodyMedium),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: '남성',
                              label: Text('남성'),
                              icon: Icon(Icons.male),
                            ),
                            ButtonSegment(
                              value: '여성',
                              label: Text('여성'),
                              icon: Icon(Icons.female),
                            ),
                            ButtonSegment(
                              value: '기타',
                              label: Text('기타'),
                              icon: Icon(Icons.transgender),
                            ),
                          ],
                          showSelectedIcon: false,
                          selected: {_selectedGenderKo},
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.15);
                              }
                              return isDark
                                  ? const Color(0xFF2C2C2C)
                                  : const Color(0xFFF9F9F9);
                            }),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          onSelectionChanged: (s) =>
                              setState(() => _selectedGenderKo = s.first),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('생일', style: textTheme.bodyMedium),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _selectedBirthday != null
                                ? DateFormat(
                                    'yyyy년 MM월 dd일',
                                  ).format(_selectedBirthday!)
                                : '생일을 선택하세요',
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _selectBirthday(context),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '정확한 생일을 입력하면 맞춤형 경험을 제공할 수 있습니다.',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 액션
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('취소'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('다음 (개인정보 확인)'),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          if (!_formKey.currentState!.validate()) return;
                          if (_selectedBirthday == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('생일을 선택하세요')),
                            );
                            return;
                          }
                          final draft = UserResponse(
                            name: _nameController.text.trim(),
                            nickname: _nicknameController.text.trim(),
                            gender: reverseGenderMap[_selectedGenderKo],
                            birthday: DateFormat(
                              'yyyy-MM-dd',
                            ).format(_selectedBirthday!),
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UserInfoConfirmScreen(
                                draft: draft,
                                onSaved: () {
                                  widget.onSaved?.call(); // 프로필 화면 갱신
                                },
                              ),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===========================================
/// 3) 개인정보 최종 확인 화면
/// ===========================================
class UserInfoConfirmScreen extends ConsumerWidget {
  const UserInfoConfirmScreen({super.key, required this.draft, this.onSaved});
  final UserResponse draft;
  final VoidCallback? onSaved;

  String _genderKo(String? code) {
    switch (code) {
      case 'MALE':
        return '남성';
      case 'FEMALE':
        return '여성';
      case 'OTHERS':
        return '기타';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNotifier = ref.read(userNotifierProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('개인정보 확인'), centerTitle: true),
        backgroundColor: isDark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF5F5F5),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 0,
            color: isDark
                ? Theme.of(context).colorScheme.surface
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DefaultTextStyle(
                style: textTheme.bodyLarge!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('제출 전 정보를 확인하세요.', style: textTheme.titleMedium),
                    const SizedBox(height: 16),
                    _ConfirmRow(label: '이름', value: draft.name ?? '-'),
                    const Divider(height: 24),
                    _ConfirmRow(label: '닉네임', value: draft.nickname ?? '-'),
                    const Divider(height: 24),
                    _ConfirmRow(label: '성별', value: _genderKo(draft.gender)),
                    const Divider(height: 24),
                    _ConfirmRow(label: '생일', value: _fmtDate(draft.birthday)),
                    const SizedBox(height: 24),
                    Text(
                      '위 정보가 정확한지 확인했으며, 저장 시 프로필에 즉시 반영됩니다.',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('수정하기'),
                  onPressed: () => Navigator.of(context).pop(), // 다이얼로그로 복귀
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('저장'),
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    await userNotifier.updateUserProfile(draft);
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('저장 완료')));
                      onSaved?.call(); // 프로필 화면 갱신 트리거
                      Navigator.of(context).pop(); // 확인 화면 닫기
                      Navigator.of(context).maybePop(); // 편집 다이얼로그 닫기
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(String? yyyyMMdd) {
    if (yyyyMMdd == null) return '-';
    try {
      final dt = DateTime.parse(yyyyMMdd);
      return DateFormat('yyyy년 MM월 dd일').format(dt);
    } catch (_) {
      return yyyyMMdd;
    }
  }
}

/// ===========================================
/// 4) 확인 화면 내부에서 쓰는 단일 행 위젯
/// ===========================================
class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: t.bodyMedium)),
      ],
    );
  }
}
