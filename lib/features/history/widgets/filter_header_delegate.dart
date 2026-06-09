import 'package:flutter/material.dart';

class FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 128;

  @override
  double get maxExtent => 128;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar proveedor, proyecto o nota',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.tune_outlined)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Chip(label: const Text('Todo')),
                      const SizedBox(width: 8),
                      Chip(label: const Text('Mano de obra')),
                      const SizedBox(width: 8),
                      Chip(label: const Text('Factura')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 18),
                    SizedBox(width: 6),
                    Text('Proyecto X'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
