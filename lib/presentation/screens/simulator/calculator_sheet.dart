import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/calculator_engine.dart';
import '../../../core/theme/app_colors.dart';

class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key});

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  final CalculatorEngine _engine = CalculatorEngine();

  @override
  void initState() {
    super.initState();
    _engine.addListener(_onEngineUpdate);
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineUpdate);
    _engine.dispose();
    super.dispose();
  }

  void _onEngineUpdate() {
    setState(() {});
  }

  Widget _buildButton(String label, {Color? bg, Color? fg, double fontSize = 13, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: Material(
          color: bg ?? AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              HapticFeedback.selectionClick();
              _engine.processKey(label);
            },
            child: Container(
              height: 42,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: fg ?? AppColors.textPrimary,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 14,
        right: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Drag Handle & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🖩', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(
                    'IIT JAM Scientific Calculator',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          // Display Screen
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _engine.history.isEmpty ? ' ' : _engine.history,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _engine.display,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rad / Deg & Memory indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Rad', style: TextStyle(fontSize: 11)),
                      selected: _engine.isRadian,
                      onSelected: (val) {
                        if (val) _engine.setAngleMode(true);
                      },
                      visualDensity: VisualDensity.compact,
                      selectedColor: AppColors.primaryGold,
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Deg', style: TextStyle(fontSize: 11)),
                      selected: !_engine.isRadian,
                      onSelected: (val) {
                        if (val) _engine.setAngleMode(false);
                      },
                      visualDensity: VisualDensity.compact,
                      selectedColor: AppColors.primaryGold,
                    ),
                  ],
                ),
                if (_engine.hasMemory)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('M', style: TextStyle(color: AppColors.primaryGold, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Keypad Rows
          Row(
            children: [
              _buildButton('MC', bg: AppColors.surfaceHighlight.withValues(alpha: 0.7)),
              _buildButton('MR', bg: AppColors.surfaceHighlight.withValues(alpha: 0.7)),
              _buildButton('MS', bg: AppColors.surfaceHighlight.withValues(alpha: 0.7)),
              _buildButton('M+', bg: AppColors.surfaceHighlight.withValues(alpha: 0.7)),
              _buildButton('M-', bg: AppColors.surfaceHighlight.withValues(alpha: 0.7)),
              _buildButton('C', bg: AppColors.accentRed.withValues(alpha: 0.25), fg: AppColors.accentRed),
              _buildButton('CE', bg: AppColors.accentRed.withValues(alpha: 0.25), fg: AppColors.accentRed),
              _buildButton('⌫', bg: AppColors.surfaceHighlight),
            ],
          ),
          Row(
            children: [
              _buildButton('sin'),
              _buildButton('cos'),
              _buildButton('tan'),
              _buildButton('ln'),
              _buildButton('log'),
              _buildButton('('),
              _buildButton(')'),
              _buildButton('÷', bg: AppColors.primaryGold.withValues(alpha: 0.2), fg: AppColors.primaryGold),
            ],
          ),
          Row(
            children: [
              _buildButton('asin'),
              _buildButton('acos'),
              _buildButton('atan'),
              _buildButton('e^x'),
              _buildButton('7', bg: AppColors.surface),
              _buildButton('8', bg: AppColors.surface),
              _buildButton('9', bg: AppColors.surface),
              _buildButton('×', bg: AppColors.primaryGold.withValues(alpha: 0.2), fg: AppColors.primaryGold),
            ],
          ),
          Row(
            children: [
              _buildButton('sinh'),
              _buildButton('cosh'),
              _buildButton('tanh'),
              _buildButton('10^x'),
              _buildButton('4', bg: AppColors.surface),
              _buildButton('5', bg: AppColors.surface),
              _buildButton('6', bg: AppColors.surface),
              _buildButton('-', bg: AppColors.primaryGold.withValues(alpha: 0.2), fg: AppColors.primaryGold),
            ],
          ),
          Row(
            children: [
              _buildButton('√'),
              _buildButton('x^2'),
              _buildButton('x^y'),
              _buildButton('1/x'),
              _buildButton('1', bg: AppColors.surface),
              _buildButton('2', bg: AppColors.surface),
              _buildButton('3', bg: AppColors.surface),
              _buildButton('+', bg: AppColors.primaryGold.withValues(alpha: 0.2), fg: AppColors.primaryGold),
            ],
          ),
          Row(
            children: [
              _buildButton('π'),
              _buildButton('e'),
              _buildButton('n!'),
              _buildButton('±'),
              _buildButton('0', bg: AppColors.surface),
              _buildButton('.', bg: AppColors.surface),
              _buildButton('%'),
              _buildButton('=', bg: AppColors.primaryGold, fg: Colors.black, fontSize: 16),
            ],
          ),
        ],
      ),
    );
  }
}

