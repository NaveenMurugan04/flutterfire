import 'package:firebase_ui/auth.dart';
import 'package:firebase_ui/i10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth_state.dart';
import '../error_text.dart';

class NumberDecorationPainter extends BoxPainter {
  final InputBorder inputBorder;
  final Color color;

  NumberDecorationPainter({
    VoidCallback? onChanged,
    required this.inputBorder,
    required this.color,
  }) : super(onChanged);

  final rect = const Rect.fromLTWH(0, 0, NUMBER_SLOT_WIDTH, NUMBER_SLOT_HEIGHT);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    inputBorder
        .copyWith(borderSide: BorderSide(color: color, width: 2))
        .paint(canvas, rect);
    canvas.restore();
  }
}

class NumberSlotDecoration extends Decoration {
  final InputBorder inputBorder;
  final Color color;

  NumberSlotDecoration({
    required this.inputBorder,
    required this.color,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return NumberDecorationPainter(
      onChanged: onChanged,
      inputBorder: inputBorder,
      color: color,
    );
  }
}

const NUMBER_SLOT_WIDTH = 44.0;
const NUMBER_SLOT_HEIGHT = 55.0;
const NUMBER_SLOT_MARGIN = 5.5;

class NumberSlot extends StatefulWidget {
  final String number;
  final VoidCallback? onTap;

  const NumberSlot({Key? key, this.number = '', this.onTap}) : super(key: key);

  @override
  _NumberSlotState createState() => _NumberSlotState();
}

class _NumberSlotState extends State<NumberSlot>
    with SingleTickerProviderStateMixin {
  bool hasError = false;

  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );

  @override
  void didUpdateWidget(covariant NumberSlot oldWidget) {
    if (oldWidget.number.isEmpty && widget.number.isNotEmpty) {
      controller.animateTo(1);
    }

    if (oldWidget.number.isNotEmpty && widget.number.isEmpty) {
      controller.animateBack(0);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = Theme.of(context).inputDecorationTheme.border;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final errorColor = Theme.of(context).errorColor;

    final color = hasError ? errorColor : primaryColor;

    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: NUMBER_SLOT_WIDTH,
        height: NUMBER_SLOT_HEIGHT,
        decoration: NumberSlotDecoration(
          inputBorder: inputBorder ?? const UnderlineInputBorder(),
          color: color,
        ),
        margin: const EdgeInsets.all(NUMBER_SLOT_MARGIN),
        child: Center(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Transform.scale(
                scale: controller.value,
                child: child,
              );
            },
            child: Text(
              widget.number,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class SMSCodeInput extends StatefulWidget {
  final bool autofocus;
  final Widget? text;

  const SMSCodeInput({Key? key, this.autofocus = true, this.text})
      : super(key: key);

  @override
  SMSCodeInputState createState() => SMSCodeInputState();
}

class SMSCodeInputState extends State<SMSCodeInput> {
  String code = '';
  late final controller = TextEditingController()..addListener(onChange);
  final focusNode = FocusNode();

  void onChange() {
    setState(() {
      code = controller.text;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    final authState = AuthState.of(context);

    if (authState is PhoneVerified) {
      controller.text = authState.credential.smsCode!;
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final l = FirebaseUILocalizations.labelsOf(context);

    final state = AuthState.of(context);

    Widget? text;
    if (state is CredentialReceived ||
        state is SigningIn ||
        state is SignedIn) {
      text = Text(l.verifyingSMSCodeText);
    }

    if (state is AuthFailed) {
      text = ErrorText(exception: state.exception);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: NUMBER_SLOT_WIDTH * 6 + NUMBER_SLOT_MARGIN * 12,
      ),
      child: Stack(
        children: [
          Opacity(
            opacity: 0,
            child: TextField(
              autofocus: true,
              focusNode: focusNode,
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state is SMSCodeRequested)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(l.sendingSMSCodeText),
                  ],
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.all(NUMBER_SLOT_MARGIN),
                  child: Text(
                    l.enterSMSCodeText,
                    style: TextStyle(color: primaryColor),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 6; i++)
                      NumberSlot(
                        number: code.length > i ? code[i] : '',
                        onTap: focusNode.requestFocus,
                      ),
                  ],
                ),
              ],
              if (widget.text != null || text != null)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: widget.text ?? text,
                )
            ],
          ),
        ],
      ),
    );
  }
}
