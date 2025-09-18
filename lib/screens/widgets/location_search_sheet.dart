import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../services/geocoding_service.dart';

typedef OnPlacePicked = void Function(String name, LatLng position);

class LocationSearchSheet extends StatefulWidget {
  const LocationSearchSheet({super.key, required this.onPicked});

  final OnPlacePicked onPicked;

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  List<GeocodingPlace> _results = const [];
  bool _loading = false;

  Future<void> _search() async {
    final q = _controller.text.trim();
    setState(() => _loading = true);
    try {
      final items = await GeocodingService.search(q);
      if (!mounted) return;
      setState(() => _results = items);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Search places... (e.g., Connaught Place, Delhi) ',
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : _search,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _results.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        return ListTile(
                          title: Text(item.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                          leading: const Icon(Icons.place),
                          onTap: () {
                            widget.onPicked(item.displayName, item.position);
                            Navigator.pop(context);
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemCount: _results.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}





