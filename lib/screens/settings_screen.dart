import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/typography.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        children: [
          _buildSectionHeader('Appearance'),
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppTheme.primaryPurple,
                ),
              ),
              title: Text(
                'Dark Mode',
                style: AppTypography.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              trailing: Switch(
                value: isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeColor: AppTheme.primaryPurple,
                activeTrackColor: AppTheme.primaryPurple.withOpacity(0.3),
              ),
            ),
          ),
          
          _buildSectionHeader('Preferences'),
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.incomeGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: AppTheme.incomeGreen,
                ),
              ),
              title: Text(
                'Currency',
                style: AppTypography.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: themeProvider.currencySymbol,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: AppTypography.poppins(
                    fontSize: 16, 
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      themeProvider.setCurrency(newValue);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: '\$', child: Text('USD (\$)')),
                    DropdownMenuItem(value: '€', child: Text('EUR (€)')),
                    DropdownMenuItem(value: '£', child: Text('GBP (£)')),
                    DropdownMenuItem(value: '¥', child: Text('JPY (¥)')),
                    DropdownMenuItem(value: '₹', child: Text('INR (₹)')),
                    DropdownMenuItem(value: 'A\$', child: Text('AUD (A\$)')),
                    DropdownMenuItem(value: 'C\$', child: Text('CAD (C\$)')),
                  ],
                ),
              ),
            ),
          ),
          
          _buildSectionHeader('Data & Sync'),
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(
                    'Backup Data',
                    style: AppTypography.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Export your local data',
                    style: AppTypography.poppins(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () async {
                    final success = await BackupService.createBackup(context);
                    if (context.mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Backup created successfully')),
                      );
                    }
                  },
                ),
                Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_backup_restore_rounded,
                      color: Colors.orange,
                    ),
                  ),
                  title: Text(
                    'Restore Data',
                    style: AppTypography.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Text(
                    'Import from a backup file',
                    style: AppTypography.poppins(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Restore Data?', style: AppTypography.poppins(fontWeight: FontWeight.w600)),
                        content: const Text(
                          'Restoring from a backup will overwrite ALL your current data. This cannot be undone.'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Restore', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      final success = await BackupService.restoreBackup(context);
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data restored successfully. Please restart the app.')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to restore data (or cancelled).')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
        ),
      ),
    );
  }
}
