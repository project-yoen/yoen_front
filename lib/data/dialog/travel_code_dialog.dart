import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class TravelCodeDialog extends StatefulWidget {
  const TravelCodeDialog({super.key});

  @override
  State<TravelCodeDialog> createState() => _TravelCodeDialogState();
}

class _TravelCodeDialogState extends State<TravelCodeDialog> {
  Future<void>? _verificationFuture;
  bool _isVerified = false;

  Future<void> verifyCode(String code) async {
    await Future.delayed(const Duration(seconds: 2)); // 예: API 호출
    // TODO: 실제 API 결과에 따라 조건 분기
    setState(() {
      _isVerified = true;
    });
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
              // LayoutBuilder가 현재 context의 constraints(길이제한) 을 계산해서 알려준다 (동적)
              maxHeight: constraints.maxHeight * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        const Text('코드 입력', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<void>(
                      future: _verificationFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: const Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        } else if (_isVerified) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 48,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '인증이 완료되었습니다!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '여행 코드',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    IconButton(
                                      onPressed: () async {
                                        final data = await Clipboard.getData(
                                          Clipboard.kTextPlain,
                                        );
                                        final text = data?.text?.trim() ?? '';
                                        if (text.length == 6 &&
                                            RegExp(
                                              r'^[A-Z0-9]{6}$',
                                            ).hasMatch(text)) {
                                          setState(() {
                                            _verificationFuture = verifyCode(
                                              text,
                                            );
                                          });
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                '유효한 6자리 코드가 클립보드에 없습니다',
                                              ),
                                            ),
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
                                  obscureText: false,
                                  animationType: AnimationType.fade,
                                  keyboardType: TextInputType.text,
                                  inputFormatters: [
                                    UpperCaseTextFormatter(),
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[A-Z0-9]'),
                                    ),
                                  ],
                                  onChanged: (_) {},
                                  onCompleted: (code) {
                                    setState(() {
                                      _verificationFuture = verifyCode(code);
                                    });
                                  },
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
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
