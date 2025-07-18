import 'dart:async';

import 'package:flutter/material.dart';

typedef FetchFunction<T> =
    Future<List<T>> Function(int page, String searchTerm);
typedef ItemBuilder<T> = Widget Function(T item);

class AsyncInfiniteList<T> extends StatefulWidget {
  final FetchFunction<T> onFetch;
  final ItemBuilder<T> itemBuilder;
  final int pageSize;

  const AsyncInfiniteList({
    super.key,
    required this.onFetch,
    required this.itemBuilder,
    this.pageSize = 10,
  });

  @override
  State<AsyncInfiniteList<T>> createState() => _AsyncInfiniteListState<T>();
}

class _AsyncInfiniteListState<T> extends State<AsyncInfiniteList<T>> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<T> _items = [];
  String _searchTerm = '';
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;

  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Pesquisar',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _items.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _items.length) {
                return widget.itemBuilder(_items[index]);
              } else {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchData(reset: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore) {
        _fetchData();
      }
    });

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _searchTerm = _searchController.text;
        _fetchData(reset: true);
      });
    });
  }

  Future<void> _fetchData({bool reset = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
      }
    });

    try {
      final fetched = await widget.onFetch(_page, _searchTerm);
      setState(() {
        if (reset) {
          _items = fetched;
        } else {
          _items.addAll(fetched);
        }
        _hasMore = fetched.length >= widget.pageSize;
        if (_hasMore) _page++;
      });
    } catch (e) {
      debugPrint('Erro ao buscar dados: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
