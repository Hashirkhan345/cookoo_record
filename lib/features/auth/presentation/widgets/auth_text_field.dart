import 'package:flutter/material.dart';

import '../../../video/presentation/controller/video_feature_theme.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableIMEPersonalizedLearning = true,
    this.autofillHints,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enableIMEPersonalizedLearning;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final String? Function(String? value)? validator;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _isTextObscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofillHints: widget.autofillHints,
      autocorrect: widget.autocorrect,
      controller: widget.controller,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
      enableSuggestions: widget.enableSuggestions,
      obscureText: _isTextObscured,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isTextObscured = !_isTextObscured;
                  });
                },
                icon: Icon(
                  _isTextObscured
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: VideoFeatureTheme.muted,
                ),
                tooltip: _isTextObscured ? 'Show password' : 'Hide password',
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: VideoFeatureTheme.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: VideoFeatureTheme.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: VideoFeatureTheme.primary),
        ),
      ),
    );
  }
}
