import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exchange_rate_provider.dart';

class ExchangeRatesScreen extends ConsumerWidget {
  const ExchangeRatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsync = ref.watch(exchangeRatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Güncel Kurlar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Provider'ı sıfırlayarak API'den tekrar veri çeker
              ref.invalidate(exchangeRatesProvider);
            },
          )
        ],
      ),
      body: ratesAsync.when(
        data: (rates) {
          if (rates.isEmpty) {
            return const Center(child: Text('Kurlar alınamadı. Lütfen daha sonra tekrar deneyin.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(exchangeRatesProvider);
            },
            child: ListView.builder(
              itemCount: rates.length,
              itemBuilder: (context, index) {
                final rate = rates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: Text(rate.currencyCode == 'GOLD' ? 'Au' : rate.currencyCode[0]),
                    ),
                    title: Text(rate.currencyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Alış: ${rate.buyingPrice.toStringAsFixed(2)} ₺ \nSatış: ${rate.sellingPrice.toStringAsFixed(2)} ₺'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Bir hata oluştu: $err')),
      ),
    );
  }
}

