import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/party.dart';
import '../models/stock_item.dart';
import '../models/transaction.dart';

class DatabaseService {
  static DatabaseService? _instance;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  static const _partiesKey = 'db:parties';
  static const _itemsKey = 'db:stock_items';
  static const _txsKey = 'db:transactions';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Parties ──────────────────────────────────────────────────────────────

  Future<List<Party>> getParties() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_partiesKey) ?? [];
    return raw.map((e) => Party.fromMap(jsonDecode(e) as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> insertParty(Party party) async {
    final prefs = await _prefs;
    final parties = await getParties();
    parties.removeWhere((p) => p.id == party.id);
    parties.insert(0, party);
    await prefs.setStringList(_partiesKey, parties.map((p) => jsonEncode(p.toMap())).toList());
  }

  Future<void> updateParty(Party party) async {
    final prefs = await _prefs;
    final parties = await getParties();
    final idx = parties.indexWhere((p) => p.id == party.id);
    if (idx != -1) parties[idx] = party;
    await prefs.setStringList(_partiesKey, parties.map((p) => jsonEncode(p.toMap())).toList());
  }

  Future<void> deleteParty(String id) async {
    final prefs = await _prefs;
    final parties = await getParties();
    parties.removeWhere((p) => p.id == id);
    await prefs.setStringList(_partiesKey, parties.map((p) => jsonEncode(p.toMap())).toList());
    final txs = await getTransactions();
    final remaining = txs.where((t) => t.partyId != id).toList();
    await prefs.setStringList(_txsKey, remaining.map((t) => jsonEncode(t.toMap())).toList());
  }

  // ── Stock Items ───────────────────────────────────────────────────────────

  Future<List<StockItem>> getStockItems() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_itemsKey) ?? [];
    return raw.map((e) => StockItem.fromMap(jsonDecode(e) as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> insertStockItem(StockItem item) async {
    final prefs = await _prefs;
    final items = await getStockItems();
    items.removeWhere((i) => i.id == item.id);
    items.insert(0, item);
    await prefs.setStringList(_itemsKey, items.map((i) => jsonEncode(i.toMap())).toList());
  }

  Future<void> updateStockItem(StockItem item) async {
    final prefs = await _prefs;
    final items = await getStockItems();
    final idx = items.indexWhere((i) => i.id == item.id);
    if (idx != -1) items[idx] = item;
    await prefs.setStringList(_itemsKey, items.map((i) => jsonEncode(i.toMap())).toList());
  }

  Future<void> deleteStockItem(String id) async {
    final prefs = await _prefs;
    final items = await getStockItems();
    items.removeWhere((i) => i.id == id);
    await prefs.setStringList(_itemsKey, items.map((i) => jsonEncode(i.toMap())).toList());
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<List<Transaction>> getTransactions() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_txsKey) ?? [];
    return raw.map((e) => Transaction.fromMap(jsonDecode(e) as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> insertTransaction(Transaction tx) async {
    final prefs = await _prefs;
    final txs = await getTransactions();
    txs.removeWhere((t) => t.id == tx.id);
    txs.insert(0, tx);
    await prefs.setStringList(_txsKey, txs.map((t) => jsonEncode(t.toMap())).toList());
  }

  Future<void> updateTransaction(Transaction tx) async {
    final prefs = await _prefs;
    final txs = await getTransactions();
    final idx = txs.indexWhere((t) => t.id == tx.id);
    if (idx != -1) txs[idx] = tx;
    await prefs.setStringList(_txsKey, txs.map((t) => jsonEncode(t.toMap())).toList());
  }

  Future<void> deleteTransaction(String id) async {
    final prefs = await _prefs;
    final txs = await getTransactions();
    txs.removeWhere((t) => t.id == id);
    await prefs.setStringList(_txsKey, txs.map((t) => jsonEncode(t.toMap())).toList());
  }

  // ── Backup & Restore ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportData() async {
    final parties = await getParties();
    final items = await getStockItems();
    final txs = await getTransactions();
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'parties': parties.map((p) => p.toMap()).toList(),
      'stock_items': items.map((i) => i.toMap()).toList(),
      'transactions': txs.map((t) => t.toMap()).toList(),
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final prefs = await _prefs;
    final parties = (data['parties'] as List?) ?? [];
    final items = (data['stock_items'] as List?) ?? [];
    final txs = (data['transactions'] as List?) ?? [];
    await prefs.setStringList(_partiesKey, parties.map((p) => jsonEncode(p)).toList());
    await prefs.setStringList(_itemsKey, items.map((i) => jsonEncode(i)).toList());
    await prefs.setStringList(_txsKey, txs.map((t) => jsonEncode(t)).toList());
  }

  Future<String> exportToJson() async {
    final data = await exportData();
    return jsonEncode(data);
  }

  Future<void> importFromJson(String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    await importData(data);
  }
}
