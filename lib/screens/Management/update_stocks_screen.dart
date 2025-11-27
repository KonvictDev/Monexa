import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:image_picker/image_picker.dart'; // 1. Import Image Picker
import 'package:path_provider/path_provider.dart'; // 2. Import Path Provider
import 'package:path/path.dart' as p; // 3. Import Path
import 'package:image/image.dart' as img; // 4. Import Image lib for thumbnails

import '../../model/product.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../utils/settings_utils.dart';

class UpdateStocksScreen extends ConsumerWidget {
  const UpdateStocksScreen({super.key});

  // --- HELPER: Thumbnail Generation ---
  Future<File?> _createThumbnail(File originalImage) async {
    try {
      final imageBytes = await originalImage.readAsBytes();
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return null;
      // Resize to width 200
      img.Image thumbnail = img.copyResize(decodedImage, width: 200);
      final appDir = await getApplicationDocumentsDirectory();
      final originalFileName = p.basenameWithoutExtension(originalImage.path);
      final thumbnailFileName = '${originalFileName}_thumb.jpg';
      final thumbnailPath = '${appDir.path}/$thumbnailFileName';
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 85));
      return thumbnailFile;
    } catch (e) {
      debugPrint("Error creating thumbnail: $e");
      return null;
    }
  }

  InputDecoration _modernInputDecoration(BuildContext context, String label) {
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
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED BOTTOM SHEET ---
  void _editBottomSheet(BuildContext context, WidgetRef ref, Product product) {
    final name = TextEditingController(text: product.name);
    final price = TextEditingController(text: product.price.toString());
    final qty = TextEditingController(text: product.quantity.toString());
    final desc = TextEditingController(text: product.description);

    // State variable for the NEW image (null means no change)
    File? newImageFile;
    final ImagePicker picker = ImagePicker();

    // 1. Get raw categories
    final rawCategories = ref.read(settingsRepositoryProvider).getProductCategories();
    final Set<String> categorySet = Set.from(rawCategories);
    if (product.category.isNotEmpty) {
      categorySet.add(product.category);
    }
    List<String> categories = categorySet.toList();
    String selectedCategory = product.category;

    if (selectedCategory.isEmpty && categories.isNotEmpty) {
      selectedCategory = categories.first;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {

          // --- LOGIC: Image Picker inside BottomSheet ---
          Future<void> pickImage(ImageSource source) async {
            try {
              final picked = await picker.pickImage(
                source: source,
                imageQuality: 70,
                maxWidth: 1024,
              );
              if (picked != null) {
                // Update local state of the bottom sheet
                setModalState(() {
                  newImageFile = File(picked.path);
                });
              }
            } catch (e) {
              debugPrint("Error picking image: $e");
            }
          }

          void showImageSourceModal() {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (ctx) { // Use ctx to avoid confusion
                return SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.camera_alt_outlined),
                        title: const Text('Take a Photo'),
                        onTap: () {
                          Navigator.pop(ctx);
                          pickImage(ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library_outlined),
                        title: const Text('Choose from Gallery'),
                        onTap: () {
                          Navigator.pop(ctx);
                          pickImage(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
          // ---------------------------------------------

          // Prepare the current image to show (Logic: New > Old > Placeholder)
          ImageProvider? imageProvider;
          if (newImageFile != null) {
            imageProvider = FileImage(newImageFile!);
          } else if (product.imagePath.isNotEmpty && File(product.imagePath).existsSync()) {
            imageProvider = FileImage(File(product.imagePath));
          }

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

                  // 🔥 UI: IMAGE PICKER AREA
                  GestureDetector(
                    onTap: showImageSourceModal,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                      ),
                      child: imageProvider != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image(image: imageProvider, fit: BoxFit.cover),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 8),
                          Text("Tap to change image", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: name,
                    decoration: _modernInputDecoration(context, 'Product Name'),
                  ),
                  const SizedBox(height: 16),

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

                          setModalState(() {
                            final updatedRaw = ref.read(settingsRepositoryProvider).getProductCategories();
                            final Set<String> updatedSet = Set<String>.from(updatedRaw);
                            updatedSet.add(newCategory);
                            categories = updatedSet.toList();
                            selectedCategory = newCategory;
                          });
                        }
                      } else {
                        setModalState(() => selectedCategory = value!);
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: price,
                    decoration: _modernInputDecoration(context, 'Price'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final repository = ref.read(productRepositoryProvider);

                            // 1. Handle Image Update if a new one was picked
                            if (newImageFile != null) {
                              try {
                                final appDir = await getApplicationDocumentsDirectory();
                                final fileName = p.basename(newImageFile!.path);
                                final permanentPath = '${appDir.path}/$fileName';

                                // Copy file
                                final savedImage = await newImageFile!.copy(permanentPath);

                                // Create Thumbnail
                                final thumbnailFile = await _createThumbnail(savedImage);

                                // Update Product Paths
                                product.imagePath = savedImage.path;
                                product.thumbnailPath = thumbnailFile?.path;

                                // 🔥 Important: Reset Cloud URLs so Sync service knows to re-upload
                                product.imageCloudUrl = null;
                                product.thumbnailCloudUrl = null;

                              } catch(e) {
                                debugPrint("Error saving new image: $e");
                              }
                            }

                            // 2. Update other fields
                            product.name = name.text;
                            product.price = double.tryParse(price.text) ?? product.price;
                            product.quantity = int.tryParse(qty.text) ?? product.quantity;
                            product.description = desc.text;
                            product.category = selectedCategory;

                            // 3. Save to Hive
                            repository.updateProduct(product);

                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Update'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    final productRepository = ref.watch(productRepositoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Stocks'),
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: productRepository.getListenable(),
        builder: (context, Box<Product> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No products available.', style: TextStyle(fontSize: 16)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: box.length,
            itemBuilder: (context, i) {
              final product = box.getAt(i)!;

              File? imageFile;
              if (product.thumbnailPath!.isNotEmpty) {
                final f = File(product.thumbnailPath!);
                if (f.existsSync()) imageFile = f;
              }
              if (imageFile == null && product.imagePath.isNotEmpty) {
                final f = File(product.imagePath);
                if (f.existsSync()) imageFile = f;
              }

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () => _editBottomSheet(context, ref, product),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageFile != null
                        ? Image.file(imageFile, width: 55, height: 55, fit: BoxFit.cover)
                        : Container(
                      width: 55, height: 55,
                      color: colorScheme.surfaceVariant.withOpacity(0.4),
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Category: ${product.category}\n₹${product.price.toStringAsFixed(2)} • Stock: ${product.quantity}',
                    style: TextStyle(color: colorScheme.outline),
                    maxLines: 3,
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      showConfirmationDialog(
                        context,
                        title: 'Delete Product?',
                        content: 'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
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