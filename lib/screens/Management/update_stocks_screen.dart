import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import '../../model/product.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/settings_repository.dart'; // <-- ADD THIS
import '../../utils/settings_utils.dart';

class UpdateStocksScreen extends ConsumerWidget {
  const UpdateStocksScreen({super.key});

  InputDecoration _modernInputDecoration(BuildContext context, String label) {
    // ... (this method is unchanged) ...
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      floatingLabelStyle: TextStyle(color: colorScheme.primary),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  // --- NEW DIALOG ---
  Future<String?> _showAddCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  // --- END NEW DIALOG ---

  // --- MODIFIED BOTTOM SHEET ---
  void _editBottomSheet(BuildContext context, WidgetRef ref, Product product) {
    final name = TextEditingController(text: product.name);
    final price = TextEditingController(text: product.price.toString());
    final qty = TextEditingController(text: product.quantity.toString());
    final desc = TextEditingController(text: product.description);
    final colorScheme = Theme.of(context).colorScheme;

    // --- CATEGORY STATE ---
    List<String> categories = ref.read(settingsRepositoryProvider).getProductCategories();
    String selectedCategory = product.category;
    // --- END CATEGORY STATE ---

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // Use StatefulBuilder to manage the category dropdown state
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ... (Drag Handle, Title) ...
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    'Edit Product',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: name,
                    decoration: _modernInputDecoration(context, 'Product Name'),
                  ),
                  const SizedBox(height: 16),

                  // --- CATEGORY DROPDOWN ---
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: _modernInputDecoration(context, 'Category').copyWith(
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: [
                      ...categories.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      )),
                      const DropdownMenuItem(
                        value: 'ADD_NEW',
                        child: Row(
                          children: [
                            Icon(Icons.add, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Add new category'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == 'ADD_NEW') {
                        final newCategory = await _showAddCategoryDialog(context);
                        if (newCategory != null && newCategory.isNotEmpty) {
                          await ref.read(settingsRepositoryProvider).addProductCategory(newCategory);
                          // Refresh list and set state
                          setModalState(() {
                            categories = ref.read(settingsRepositoryProvider).getProductCategories();
                            selectedCategory = newCategory;
                          });
                        }
                      } else {
                        setModalState(() => selectedCategory = value!);
                      }
                    },
                  ),
                  // --- END CATEGORY DROPDOWN ---

                  const SizedBox(height: 16),
                  TextField(
                    controller: price,
                    decoration: _modernInputDecoration(context, 'Price'),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: qty,
                    decoration: _modernInputDecoration(context, 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: desc,
                    decoration: _modernInputDecoration(context, 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      // ... (Cancel button) ...
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            final repository = ref.read(productRepositoryProvider);

                            product.name = name.text;
                            product.price =
                                double.tryParse(price.text) ?? product.price;
                            product.quantity =
                                int.tryParse(qty.text) ?? product.quantity;
                            product.description = desc.text;
                            product.category = selectedCategory; // <-- ADD THIS

                            repository.updateProduct(product);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Update'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... (build method is unchanged) ...
    final productRepository = ref.watch(productRepositoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Stocks'),
        elevation: 0, // keep default color
      ),
      body: ValueListenableBuilder(
        valueListenable: productRepository.getListenable(),
        builder: (context, Box<Product> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                'No products available.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: box.length,
            itemBuilder: (context, i) {
              final product = box.getAt(i)!;

              // --- Image logic ---
              String? imagePathToShow = product.thumbnailPath;
              File? imageFile;

              if (imagePathToShow != null && imagePathToShow.isNotEmpty) {
                final file = File(imagePathToShow);
                if (file.existsSync()) {
                  imageFile = file;
                } else {
                  imagePathToShow = null;
                }
              }
              if (imageFile == null && product.imagePath.isNotEmpty) {
                final file = File(product.imagePath);
                if (file.existsSync()) {
                  imageFile = file;
                  imagePathToShow = product.imagePath;
                }
              }
              // --- End image logic ---

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  onTap: () => _editBottomSheet(context, ref, product),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageFile != null
                        ? Image.file(
                      imageFile,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image_outlined),
                    )
                        : Container(
                      width: 55,
                      height: 55,
                      color: colorScheme.surfaceVariant.withOpacity(0.4),
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Category: ${product.category}\n₹${product.price.toStringAsFixed(2)} • Stock: ${product.quantity}', // <-- MODIFIED
                    style: TextStyle(color: colorScheme.outline),
                    maxLines: 3,
                  ),
                  isThreeLine: true, // <-- ADD THIS
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      showConfirmationDialog(
                        context,
                        title: 'Delete Product?',
                        content:
                        'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
                        onConfirm: () {
                          productRepository.deleteProduct(product);
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}