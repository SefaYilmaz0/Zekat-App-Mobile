import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../domain/asset_model.dart';
import '../../../calculator/presentation/calculator_provider.dart';
import '../../../exchange_rates/presentation/exchange_rate_provider.dart';

class AddAssetDialog extends ConsumerStatefulWidget {
  const AddAssetDialog({super.key});

  @override
  ConsumerState<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends ConsumerState<AddAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isCategorySelected = false;
  AssetCategory _selectedCategory = AssetCategory.cash;

  // Gold Form State
  String _goldType = 'Gram';
  String _purity = '24';
  final _goldQuantityController = TextEditingController();

  // Cash/Debt/Receivable Form State
  String _currency = 'TRY';
  final _cashAmountController = TextEditingController();

  // Livestock Form State
  String _livestockType = 'Koyun/Keçi';
  final _livestockQuantityController = TextEditingController();
  final _livestockUnitPriceController = TextEditingController();

  // Agriculture Form State
  final _agricultureNameController = TextEditingController();
  String _irrigationType = 'natural';
  final _agricultureValueController = TextEditingController();

  @override
  void dispose() {
    _goldQuantityController.dispose();
    _cashAmountController.dispose();
    _livestockQuantityController.dispose();
    _livestockUnitPriceController.dispose();
    _agricultureNameController.dispose();
    _agricultureValueController.dispose();
    super.dispose();
  }

  Widget _buildCategoryGrid(bool isTr) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text(isTr ? 'Vazgeç' : 'Cancel', style: TextStyle(color: Colors.grey.shade600))
            ),
            Text(isTr ? 'Varlık Ekle' : 'Add Asset', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 64), 
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: AssetCategory.values.map((cat) {
            Color bgColor, iconColor;
            IconData icon;
            String name;
            if (cat == AssetCategory.gold) { bgColor = const Color(0xFFFEF3C7); iconColor = const Color(0xFFF3A712); icon = Icons.grid_goldenratio_rounded; name = isTr ? 'Altın' : 'Gold'; }
            else if (cat == AssetCategory.cash) { bgColor = const Color(0xFFD1FAE5); iconColor = const Color(0xFF10B981); icon = Icons.payments_rounded; name = isTr ? 'Nakit' : 'Cash'; }
            else if (cat == AssetCategory.debt) { bgColor = const Color(0xFFFEE2E2); iconColor = const Color(0xFFEF4444); icon = Icons.money_off_rounded; name = isTr ? 'Borç / Gider' : 'Debt'; }
            else if (cat == AssetCategory.receivable) { bgColor = const Color(0xFFDBEAFE); iconColor = const Color(0xFF3B82F6); icon = Icons.account_balance_rounded; name = isTr ? 'Alacaklar' : 'Receivables'; }
            else if (cat == AssetCategory.livestock) { bgColor = const Color(0xFFFFEDD5); iconColor = const Color(0xFFF97316); icon = Icons.pets_rounded; name = isTr ? 'Hayvanlar' : 'Livestock'; }
            else { bgColor = const Color(0xFFDCFCE7); iconColor = const Color(0xFF22C55E); icon = Icons.agriculture_rounded; name = isTr ? 'Tarım Ürünleri' : 'Agriculture'; }

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  _isCategorySelected = true;
                  // Reset states on selection
                  _currency = 'TRY';
                  _goldType = 'Gram';
                  _purity = '24';
                  _livestockType = 'Koyun/Keçi';
                  _irrigationType = 'natural';
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                      child: Icon(icon, color: iconColor, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGoldForm(bool isTr) {
    final goldRateAsync = ref.watch(goldRateProvider);
    final goldPrice = goldRateAsync.value ?? 3650.0; 

    final goldTypes = isTr
        ? ['Gram', 'Çeyrek', 'Yarım', 'Tam', 'Cumhuriyet', 'Ata']
        : ['Gram', 'Quarter', 'Half', 'Full', 'Republic', 'Ata'];

    double getPurityFactor(String k) {
      switch (k) {
        case '24': return 1.0;
        case '22': return 0.916;
        case '18': return 0.75;
        case '14': return 0.585;
        default: return 1.0;
      }
    }

    double getUnitGoldPrice() {
      if (_goldType == 'Gram') {
        return goldPrice * getPurityFactor(_purity);
      }
      switch (_goldType) {
        case 'Çeyrek':
        case 'Quarter':
          return goldPrice * 1.64;
        case 'Yarım':
        case 'Half':
          return goldPrice * 3.28;
        case 'Tam':
        case 'Full':
          return goldPrice * 6.56;
        case 'Cumhuriyet':
        case 'Republic':
          return goldPrice * 6.68;
        case 'Ata':
          return goldPrice * 6.75;
        default:
          return goldPrice * getPurityFactor(_purity);
      }
    }

    final unitPrice = getUnitGoldPrice();
    final quantity = double.tryParse(_goldQuantityController.text) ?? 0.0;
    final totalValue = quantity * unitPrice;

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
                onPressed: () => setState(() => _isCategorySelected = false),
              ),
              const SizedBox(width: 8),
              Text(isTr ? 'Altın Ekle' : 'Add Gold', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Text(isTr ? 'ALTIN TÜRÜ' : 'GOLD TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: goldTypes.map((type) {
              final isSelected = _goldType == type;
              return ChoiceChip(
                label: Text(type, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                selected: isSelected,
                selectedColor: const Color(0xFFF3A712),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _goldType = type;
                      if (type != 'Gram') {
                        _purity = '22';
                      } else {
                        _purity = '24';
                      }
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          if (_goldType == 'Gram') ...[
            Text(isTr ? 'AYAR' : 'PURITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Row(
              children: ['24', '22', '18', '14'].map((k) {
                final isSelected = _purity == k;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? const Color(0xFFF3A712).withOpacity(0.1) : Colors.transparent,
                        side: BorderSide(color: isSelected ? const Color(0xFFF3A712) : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => setState(() => _purity = k),
                      child: Text('$k Ayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? const Color(0xFFF3A712) : Colors.black54)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _goldQuantityController,
            decoration: InputDecoration(
              labelText: _goldType == 'Gram' ? (isTr ? 'Miktar (Gram)' : 'Quantity (Gram)') : (isTr ? 'Miktar (Adet)' : 'Quantity (Pcs)'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: _goldType == 'Gram' ? 'gr' : (isTr ? 'adet' : 'pcs'),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir miktar girin' : 'Please enter a quantity') : null,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isTr ? 'Birim Fiyat' : 'Unit Price', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text('₺${unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(isTr ? 'Toplam Tutar' : 'Total Value', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Text('₺${totalValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF3A712))),
                  ],
                ),
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
                    final assetName = _goldType == 'Gram' ? '$_purity ${isTr ? "Ayar Altın" : "K karat Gold"}' : '$_goldType ${isTr ? "Altın" : "Gold"}';
                    final asset = AssetModel(
                      id: const Uuid().v4(),
                      name: assetName,
                      category: AssetCategory.gold,
                      value: totalValue,
                      details: {
                        'goldType': _goldType,
                        'purity': _purity,
                        'originalQuantity': _goldQuantityController.text,
                        'unitPrice': unitPrice,
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

  Widget _buildCashForm(bool isTr) {
    final ratesAsync = ref.watch(exchangeRatesProvider);
    final rates = ratesAsync.value ?? [];
    
    double usdPrice = 46.0;
    double eurPrice = 53.0;
    
    for (var r in rates) {
      if (r.currencyCode == 'USD') usdPrice = r.buyingPrice;
      if (r.currencyCode == 'EUR') eurPrice = r.buyingPrice;
    }

    double getRate() {
      if (_currency == 'USD') return usdPrice;
      if (_currency == 'EUR') return eurPrice;
      return 1.0;
    }

    final currentRate = getRate();
    final amount = double.tryParse(_cashAmountController.text) ?? 0.0;
    final totalValue = amount * currentRate;

    String getTitle() {
      if (_selectedCategory == AssetCategory.debt) return isTr ? 'Borç Ekle' : 'Add Debt';
      if (_selectedCategory == AssetCategory.receivable) return isTr ? 'Alacak Ekle' : 'Add Receivable';
      return isTr ? 'Nakit Ekle' : 'Add Cash';
    }

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
                onPressed: () => setState(() => _isCategorySelected = false),
              ),
              const SizedBox(width: 8),
              Text(getTitle(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Text(isTr ? 'PARA BİRİMİ' : 'CURRENCY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(
            children: ['TRY', 'USD', 'EUR'].map((c) {
              final isSelected = _currency == c;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? const Color(0xFFF3A712).withOpacity(0.1) : Colors.transparent,
                      side: BorderSide(color: isSelected ? const Color(0xFFF3A712) : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => setState(() => _currency = c),
                    child: Text(c, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFFF3A712) : Colors.black54)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cashAmountController,
            decoration: InputDecoration(
              labelText: isTr ? 'Tutar' : 'Amount',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: _currency,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir tutar girin' : 'Please enter an amount') : null,
          ),
          const SizedBox(height: 16),
          if (_currency != 'TRY') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isTr ? 'Kur ($_currency/TRY)' : 'Rate ($_currency/TRY)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text('₺${currentRate.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(isTr ? 'Toplam (TRY)' : 'Total (TRY)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(height: 4),
                      Text('₺${totalValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF3A712))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
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
                    String categoryName = '';
                    if (_selectedCategory == AssetCategory.debt) {
                      categoryName = isTr ? 'Borç' : 'Debt';
                    } else if (_selectedCategory == AssetCategory.receivable) {
                      categoryName = isTr ? 'Alacak' : 'Receivable';
                    } else {
                      categoryName = isTr ? 'Nakit' : 'Cash';
                    }

                    final asset = AssetModel(
                      id: const Uuid().v4(),
                      name: '$_currency $categoryName',
                      category: _selectedCategory,
                      value: totalValue,
                      details: {
                        'amount': _cashAmountController.text,
                        'currency': _currency,
                        'exchangeRate': currentRate,
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

  Widget _buildLivestockForm(bool isTr) {
    final quantity = double.tryParse(_livestockQuantityController.text) ?? 0.0;
    final unitPrice = double.tryParse(_livestockUnitPriceController.text) ?? 0.0;
    final totalValue = quantity * unitPrice;

    final animalTypes = isTr
        ? ['Koyun/Keçi', 'Sığır/Manda', 'Deve']
        : ['Sheep/Goat', 'Cattle/Buffalo', 'Camel'];

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
                onPressed: () => setState(() => _isCategorySelected = false),
              ),
              const SizedBox(width: 8),
              Text(isTr ? 'Hayvan Ekle' : 'Add Livestock', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Text(isTr ? 'HAYVAN TÜRÜ' : 'LIVESTOCK TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(
            children: animalTypes.map((type) {
              final isSelected = _livestockType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? const Color(0xFFF3A712).withOpacity(0.1) : Colors.transparent,
                      side: BorderSide(color: isSelected ? const Color(0xFFF3A712) : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() => _livestockType = type),
                    child: Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isSelected ? const Color(0xFFF3A712) : Colors.black54)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _livestockQuantityController,
            decoration: InputDecoration(
              labelText: isTr ? 'Adet' : 'Quantity',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: isTr ? 'adet' : 'pcs',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir miktar girin' : 'Please enter a quantity') : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _livestockUnitPriceController,
            decoration: InputDecoration(
              labelText: isTr ? 'Birim Değer (TRY)' : 'Unit Value (TRY)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixText: 'TRY',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => setState(() {}),
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen bir birim değer girin' : 'Please enter a unit value') : null,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isTr ? 'Tahmini Toplam:' : 'Estimated Total:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('₺${totalValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF3A712))),
            ],
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
                      name: '$_livestockType ${isTr ? '(Hayvan)' : '(Livestock)'}',
                      category: AssetCategory.livestock,
                      value: totalValue,
                      details: {
                        'livestockType': _livestockType,
                        'quantity': _livestockQuantityController.text,
                        'unitPrice': _livestockUnitPriceController.text,
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

  Widget _buildAgricultureForm(bool isTr) {
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
                onPressed: () => setState(() => _isCategorySelected = false),
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
                      backgroundColor: _irrigationType == 'natural' ? const Color(0xFFF3A712).withOpacity(0.1) : Colors.transparent,
                      side: BorderSide(color: _irrigationType == 'natural' ? const Color(0xFFF3A712) : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => setState(() => _irrigationType = 'natural'),
                    child: Column(
                      children: [
                        Text(isTr ? 'Doğal' : 'Natural', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _irrigationType == 'natural' ? const Color(0xFFF3A712) : Colors.black54)),
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
                      backgroundColor: _irrigationType == 'artificial' ? const Color(0xFFF3A712).withOpacity(0.1) : Colors.transparent,
                      side: BorderSide(color: _irrigationType == 'artificial' ? const Color(0xFFF3A712) : Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => setState(() => _irrigationType = 'artificial'),
                    child: Column(
                      children: [
                        Text(isTr ? 'Yapay' : 'Artificial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _irrigationType == 'artificial' ? const Color(0xFFF3A712) : Colors.black54)),
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
            validator: (val) => val == null || val.isEmpty ? (isTr ? 'Lütfen değeri girin' : 'Please enter value') : null,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
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
                      name: '${_agricultureNameController.text} ${isTr ? '(Tarım)' : '(Agriculture)'}',
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

  Widget _buildForm(bool isTr) {
    switch (_selectedCategory) {
      case AssetCategory.gold:
        return _buildGoldForm(isTr);
      case AssetCategory.cash:
      case AssetCategory.receivable:
      case AssetCategory.debt:
        return _buildCashForm(isTr);
      case AssetCategory.livestock:
        return _buildLivestockForm(isTr);
      case AssetCategory.agriculture:
        return _buildAgricultureForm(isTr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isTr = appState.language == Language.tr;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isCategorySelected ? _buildForm(isTr) : _buildCategoryGrid(isTr),
        ),
      ),
    );
  }
}
