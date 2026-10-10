import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class PriceText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool showCurrency;

  const PriceText({
    super.key,
    required this.amount,
    this.style,
    this.showCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: showCurrency ? AppConstants.currencySymbol : '',
      decimalDigits: amount % 1 == 0 ? 0 : 2,
      locale: 'en_IN',
    );

    final defaultStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        );

    return Text(
      formatter.format(amount),
      style: style ?? defaultStyle,
    );
  }
}
