import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../notifier/join_notifier.dart';

class TravelCodeDialog extends ConsumerStatefulWidget {
  const TravelCodeDialog({super.key});

  @override
  ConsumerState<TravelCodeDialog> createState() => _TravelCodeDialogState();
}

class _TravelCodeDialogState extends ConsumerState<TravelCodeDialog> {
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<void> verifyCode(WidgetRef ref, String code) async {
    final joinNotifier = ref.read(joinNotifierProvider);
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      await ref.read(joinNotifierProvider.notifier).joinTravelByCode(code);
      setState(() {
        successMessage = joinNotifier.message ?? "여행 가입신청 완료";
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        errorMessage = joinNotifier.errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void resetState() {
    setState(() {
      isLoading = false;
      errorMessage = null;
      successMessage = null;
    });
  }

  Widget buildContent() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (successMessage != null) {
      return Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 8),
          Text(
            successMessage!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: const TextStyle(fontSize: 14, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: resetState,
                child: const Text('다시 시도하기'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '여행 코드',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final text = data?.text?.trim() ?? '';
                  resetState();
                  if (text.length == 6 &&
                      RegExp(r'^[A-Z0-9]{6}$').hasMatch(text)) {
                    verifyCode(ref, text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('유효한 6자리 코드가 클립보드에 없습니다')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PinCodeTextField(
            appContext: context,
            length: 6,
            autoFocus: true,
            animationType: AnimationType.fade,
            keyboardType: TextInputType.text,
            inputFormatters: [
              UpperCaseTextFormatter(),
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            ],
            onChanged: (_) {},
            onCompleted: (code) => verifyCode(ref, code),
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(8),
              fieldHeight: 50,
              fieldWidth: 40,
              activeColor: Colors.blue,
              selectedColor: Colors.blueAccent,
              inactiveColor: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Yoen은 당신의 여행을 어쩌구.. 하기 위한 서비스입니다',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: constraints.maxHeight * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('코드 입력', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    buildContent(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
