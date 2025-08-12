import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PromoCodeWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onApplied;
  final Function() onCleared;
  final String? appliedCode;

  const PromoCodeWidget({
    Key? key,
    required this.controller,
    required this.onApplied,
    required this.onCleared,
    this.appliedCode,
  }) : super(key: key);

  @override
  State<PromoCodeWidget> createState() => _PromoCodeWidgetState();
}

class _PromoCodeWidgetState extends State<PromoCodeWidget> {
  bool _isValidating = false;
  String? _errorMessage;

  Future<void> _validateAndApplyCode() async {
    final code = widget.controller.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final monetization = Provider.of<MonetizationManager>(context, listen: false);
      final validation = await monetization.referral.validatePromoCode(code);

      if (validation.isValid) {
        widget.onApplied(code);
        // Track promo code applied
        monetization.analytics.trackEvent('promo_code_applied', {
          'code': code,
          'discount_percent': validation.promoCode?.discountPercent,
          'discount_amount': validation.discountAmount,
        });
      } else {
        setState(() {
          _errorMessage = validation.errorMessage;
        });
        // Track invalid promo code
        monetization.analytics.trackEvent('promo_code_invalid', {
          'code': code,
          'error': validation.errorMessage,
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to validate code: $e';
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  void _clearCode() {
    widget.onCleared();
    setState(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasAppliedCode = widget.appliedCode != null;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight)
            .withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAppliedCode
              ? Colors.green.withValues(alpha: 0.5)
              : (_errorMessage != null
                  ? Colors.red.withValues(alpha: 0.5)
                  : (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                      .withValues(alpha: 0.2)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasAppliedCode ? Icons.check_circle : Icons.local_offer,
                color: hasAppliedCode
                    ? Colors.green
                    : (isDark ? AppTheme.primaryDark : AppTheme.primaryLight),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                hasAppliedCode ? 'Promo Applied!' : 'Have a promo code?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasAppliedCode ? Colors.green : null,
                    ),
              ),
            ],
          ),

          if (!hasAppliedCode) ...[
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    decoration: InputDecoration(
                      hintText: 'Enter promo code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _validateAndApplyCode(),
                  ),
                ),
                SizedBox(width: 2.w),
                ElevatedButton(
                  onPressed: _isValidating ? null : _validateAndApplyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isValidating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              SizedBox(height: 1.h),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
              ),
            ],
          ] else ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    widget.appliedCode!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: _clearCode,
                  child: Text(
                    'Remove',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Show available promo codes hint
          if (!hasAppliedCode) ...[
            SizedBox(height: 2.h),
            Consumer<MonetizationManager>(
              builder: (context, monetization, child) {
                final availableCodes = monetization.referral.getAvailablePromoCodes();
                if (availableCodes.isEmpty) return SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available codes:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: availableCodes.take(3).map((promo) {
                        return GestureDetector(
                          onTap: () {
                            widget.controller.text = promo.code;
                            _validateAndApplyCode();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${promo.code} (${promo.discountPercent}% off)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}