import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/domain/enums.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../domain/asset_model.dart';

class AgricultureAssetForm extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const AgricultureAssetForm({super.key, required this.onBack});

  @override
  ConsumerState<AgricultureAssetForm> createState() => _AgricultureAssetFormState();
}

class _AgricultureAssetFormState extends ConsumerState<AgricultureAssetForm> {
  final _formKey = GlobalKey<FormState>();
  final _agricultureNameController = TextEditingController();
  String _irrigationType = 'natural';
  final _agricultureValueController = TextEditingController();

  @override
  void dispose() {
    _agricultureNameController.dispose();
    _agricultureValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;

    final amount = double.tryParse(_agricultureValueController.text) ?? 0.0;
    final ratePercent = _irrigationType == 'natural' ? '10% (Öşür)' : '5% (Yapay/Sulama)';

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              Text(isTr ? 'Tarım Ürünü Ekle' : 'Add Agriculture', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _agricultureNameController,
            decoration: InputDecoration(
              labelText: isTr ? 'Ürün Tanımı (Örn: Buğday, Arpa)' : 'Product Name (e.g. Wheat)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir ürün adı girin' : 'Please enter a product name') : null,
          ),
          const SizedBox(height: 16),
          Text(isTr ? 'SULAMA YÖNTEMİ' : 'IRRIGATION TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _irrigationType == 'natural' ? const Color(0xFFF3A712).withValues(alpha: 0.1) : Colors.transparent,
                      side: BorderSide(color: _irrigationType == 'natural' ? const Color(0xFFF3A712) : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => setState(() => _irrigationType = 'natural'),
                    child: Column(
                      children: [
                        Text(isTr ? 'Doğal' : 'Natural', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _irrigationType == 'natural' ? const Color(0xFFF3A712) : (appState.isDark ? Colors.white70 : Colors.black54))),
                        Text(isTr ? 'Masrafsız' : 'Cost-free', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _irrigationType == 'artificial' ? const Color(0xFFF3A712).withValues(alpha: 0.1) : Colors.transparent,
                      side: BorderSide(color: _irrigationType == 'artificial' ? const Color(0xFFF3A712) : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => setState(() => _irrigationType = 'artificial'),
                    child: Column(
                      children: [
                        Text(isTr ? 'Yapay' : 'Artificial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _irrigationType == 'artificial' ? const Color(0xFFF3A712) : (appState.isDark ? Colors.white70 : Colors.black54))),
                        Text(isTr ? 'Masraflı' : 'Costly', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _agricultureValueController,
            decoration: InputDecoration(
              labelText: isTr ? 'Toplam Değer (TRY)' : 'Total Value (TRY)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: 'TRY',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen değeri girin' : 'Please enter value') : null,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appState.isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: appState.isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isTr ? 'Zekat Oranı:' : 'Zakat Rate:', style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(ratePercent, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF3A712))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isTr ? 'İptal' : 'Cancel', style: TextStyle(color: Colors.grey.shade600)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final asset = AssetModel(
                      id: const Uuid().v4(),
                      name: '${_agricultureNameController.text} ${isTr ? "(Tarım)" : "(Agriculture)"}',
                      category: AssetCategory.agriculture,
                      value: amount,
                      details: {
                        'irrigationType': _irrigationType,
                      },
                    );
                    final box = Hive.box<AssetModel>('assets');
                    box.put(asset.id, asset);
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3A712),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isTr ? 'Kaydet' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
