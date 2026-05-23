import 'package:flutter/material.dart';
import 'custom_button.dart';
import 'duolingo_button.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DuolingoButton(
      title: label,
      onPressed: onPressed,
      loading: isLoading,
      icon: icon,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      isPrimary: false,
    );
  }
}
