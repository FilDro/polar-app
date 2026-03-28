import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/ble_service.dart';
import '../services/files_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final _ble = BleService.instance;
  final _files = FilesService();

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onChanged);
    _files.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ble.removeListener(_onChanged);
    _files.removeListener(_onChanged);
    _files.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _exportCsv(String filename, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$filename';
    await File(path).writeAsString(content);
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }

  @override
  Widget build(BuildContext context) {
    final colors = KineColors.of(context);
    final isConnected = _ble.isConnected;
    final isSyncing = _files.isSyncing;
    final entries = _files.entries;
    final downloads = _files.downloads;

    return Scaffold(
      appBar: AppBar(title: const Text('Recordings')),
      body: Padding(
        padding: const EdgeInsets.all(KineSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isConnected)
              _Banner('Connect a sensor first', colors.warning, colors),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: !isConnected || isSyncing
                        ? null
                        : () => _files.listFiles(),
                    icon: const Icon(Icons.list),
                    label: const Text('List Files'),
                  ),
                ),
                const SizedBox(width: KineSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: !isConnected || isSyncing
                        ? null
                        : () => _files.syncFiles(),
                    icon: isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(isSyncing ? 'Syncing...' : 'Sync All'),
                  ),
                ),
              ],
            ),

            if (_files.progressText.isNotEmpty) ...[
              const SizedBox(height: KineSpacing.sm),
              Text(
                _files.progressText,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],

            const SizedBox(height: KineSpacing.md),

            // File list
            if (entries.isNotEmpty && downloads.isEmpty) ...[
              Text(
                'Files on Device',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: KineSpacing.sm),
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: KineSpacing.xs),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: _TypeIcon(e.dataType, colors),
                        title: Text(e.dataType, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${e.date}  ${_formatSize(e.sizeBytes.toInt())}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          e.path.split('/').last,
                          style: TextStyle(fontSize: 11, color: colors.textMuted),
                        ),
                        dense: true,
                      ),
                    );
                  },
                ),
              ),
            ],

            // Downloaded CSVs
            if (downloads.isNotEmpty) ...[
              Text(
                'Downloaded Recordings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: KineSpacing.sm),
              Expanded(
                child: ListView.separated(
                  itemCount: downloads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: KineSpacing.xs),
                  itemBuilder: (context, i) {
                    final d = downloads[i];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: _TypeIcon(d.dataType, colors),
                        title: Text(
                          d.filename,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${d.dataType} — ${d.sampleCount} samples',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility, color: colors.primary, size: 20),
                              tooltip: 'Preview',
                              onPressed: () => _showPreview(context, d.filename, d.csvContent, colors),
                            ),
                            IconButton(
                              icon: Icon(Icons.share, color: colors.primary, size: 20),
                              tooltip: 'Export',
                              onPressed: () => _exportCsv(d.filename, d.csvContent),
                            ),
                          ],
                        ),
                        dense: true,
                      ),
                    );
                  },
                ),
              ),
            ],

            if (entries.isEmpty && downloads.isEmpty && !isSyncing)
              Expanded(
                child: Center(
                  child: Text(
                    'Tap "List Files" to see recordings on the sensor,\nor "Sync All" to download and parse them.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPreview(BuildContext context, String filename, String csv, KineColors colors) {
    final lines = csv.split('\n').take(20).join('\n');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(KineSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      filename,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: KineSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    lines,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

class _TypeIcon extends StatelessWidget {
  final String dataType;
  final KineColors colors;

  const _TypeIcon(this.dataType, this.colors);

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (dataType.toUpperCase()) {
      'ACC' => (Icons.straighten, KineColors.blue3),
      'GYRO' => (Icons.rotate_right, KineColors.green2),
      'MAG' => (Icons.explore, KineColors.orange1),
      'HR' => (Icons.favorite, KineColors.red3),
      'PPG' => (Icons.waves, Color(0xFFB07AA1)),
      'PPI' => (Icons.timeline, KineColors.gold2),
      _ => (Icons.insert_drive_file, colors.textMuted),
    };
    return Icon(icon, color: color, size: 24);
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final Color color;
  final KineColors colors;

  const _Banner(this.text, this.color, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KineSpacing.inset),
      margin: const EdgeInsets.only(bottom: KineSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(KineRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
    );
  }
}
