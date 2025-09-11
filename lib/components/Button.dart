import 'package:flutter/material.dart';
import 'package:glacier/themes/app_colors.dart';
import 'package:glacier/themes/theme_extensions.dart';

class Button extends StatefulWidget {
  final bool? isLoading;
  final String label;
  final String? loadingLabel;
  final bool? outline;
  final VoidCallback onPressed;
  final ButtonStyle? style;

  const Button({
    super.key,
    this.isLoading,
    this.outline = false,
    this.label = 'Submit',
    this.loadingLabel = 'Loading...',
    required this.onPressed,
    this.style,
  });

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: widget.isLoading == true ? null : widget.onPressed,
        style: widget.style?.copyWith(
          backgroundColor:
              widget.outline == true
                  ? WidgetStateProperty.all(Colors.transparent)
                  : null,
          side:
              widget.outline == true
                  ? WidgetStateProperty.all(
                    BorderSide(
                      color:
                          context.isDarkMode
                              ? AppColors.lightOnSurfaceVariant
                              : AppColors.darkOnSurfaceVariant,
                    ),
                  )
                  : null,
        ),

        child:
            widget.isLoading == true
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      widget.loadingLabel!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
                : Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }
}
