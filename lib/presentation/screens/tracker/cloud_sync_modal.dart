import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/cloud_sync_service.dart';
import '../../../core/theme/app_colors.dart';

class CloudSyncModal extends StatefulWidget {
  const CloudSyncModal({super.key});

  @override
  State<CloudSyncModal> createState() => _CloudSyncModalState();
}

class _CloudSyncModalState extends State<CloudSyncModal> {
  final CloudSyncService _sync = CloudSyncService.instance;
  final TextEditingController _linkCodeController = TextEditingController();
  int _activeTab = 0; // 0 = My Code, 1 = Link Device

  @override
  void initState() {
    super.initState();
    _activeTab = _sync.isLinked ? 0 : 1;
    _sync.addListener(_onSyncUpdate);
    if (_sync.isLinked) {
      _sync.syncNow();
    }
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncUpdate);
    _linkCodeController.dispose();
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) setState(() {});
  }

  void _copySyncCode() {
    if (_sync.syncCode != null) {
      Clipboard.setData(ClipboardData(text: _sync.syncCode!));
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync code copied: ${_sync.syncCode!}'),
          backgroundColor: AppColors.surfaceElevated,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleLinkDevice() async {
    final code = _linkCodeController.text.trim();
    if (code.isEmpty) return;

    final success = await _sync.linkDevice(code);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully linked and merged with cloud data!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_sync.statusMessage.isNotEmpty ? _sync.statusMessage : 'Failed to link device'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('☁️', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 8),
                    Text(
                      'Instant 6-Digit Cloud Sync',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'Sync your PYQ solving progress seamlessly between your phone and website — zero login required.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Tabs Switcher
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeTab = 0),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeTab == 0 ? AppColors.primaryGold : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'My Sync Code',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: _activeTab == 0 ? Colors.black : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeTab = 1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeTab == 1 ? AppColors.primaryGold : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Link Website / Device',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: _activeTab == 1 ? Colors.black : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_activeTab == 0) _buildMyCodeView() else _buildLinkDeviceView(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCodeView() {
    final isLinked = _sync.isLinked;
    final code = isLinked ? _sync.syncCode! : 'No Code Active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sync Code Display Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text(
                isLinked ? 'YOUR 6-DIGIT SYNC CODE' : 'CLOUD SYNC CODE',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              SelectableText(
                code,
                style: TextStyle(
                  fontSize: isLinked ? 28 : 20,
                  fontWeight: FontWeight.w900,
                  color: isLinked ? AppColors.primaryGold : AppColors.textSecondary,
                  letterSpacing: isLinked ? 2 : 1,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              if (isLinked)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 15),
                      label: const Text('Copy Code', style: TextStyle(fontSize: 12)),
                      onPressed: _copySyncCode,
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.link_off, size: 15, color: AppColors.accentRed),
                      label: const Text('Unlink', style: TextStyle(fontSize: 12, color: AppColors.accentRed)),
                      onPressed: () => _sync.unlink(),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Generate Sync Code'),
                  onPressed: () => _sync.syncNow(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Sync Status Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _sync.isSyncing ? AppColors.accentCyan : AppColors.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _sync.isSyncing ? 'Syncing...' : (_sync.lastSyncTime != null ? 'Synced' : 'Ready to sync'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: _sync.isSyncing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.sync, size: 16),
                label: const Text('Sync Now', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                onPressed: _sync.isSyncing ? null : () => _sync.syncNow(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Info Tip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💡', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter this code on the academic website under "Cloud Sync" to connect your browser and phone together!',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkDeviceView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Sync Code from Website or Other Device:',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _linkCodeController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: 'e.g. JAM-842-195 or 842195',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14, letterSpacing: 0),
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: const Icon(Icons.qr_code_2, color: AppColors.primaryGold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _sync.isSyncing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Icon(Icons.link, size: 18),
            label: const Text('Link & Merge Progress'),
            onPressed: _sync.isSyncing ? null : _handleLinkDevice,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔄 Conflict-Free Smart Merge',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
              ),
              SizedBox(height: 4),
              Text(
                'Linking will combine solved questions from both your phone and desktop. Questions solved on either device will never be lost.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

