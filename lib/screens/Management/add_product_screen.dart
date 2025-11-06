// lib/screens/add_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

import '../../repositories/product_repository.dart';
import '../../repositories/settings_repository.dart'; // <-- ADD THIS

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();
  final _qty = TextEditingController();
  final _picker = ImagePicker();
  File? _image;
  bool _isSaving = false;

  // --- NEW CATEGORY STATE ---
  late List<String> _categories;
  String? _selectedCategory;
  // --- END NEW CATEGORY STATE ---

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categories = ref.read(settingsRepositoryProvider).getProductCategories();
    });
  }

  // --- NEW METHOD ---
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
  // --- END NEW METHOD ---


  Future<void> _pickImage() async {
    // ... (this method is unchanged) ...
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<File?> _createThumbnail(File originalImage) async {
    // ... (this method is unchanged) ...
    try {
      final imageBytes = await originalImage.readAsBytes();
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return null;
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

  void _resetForm() {
    setState(() {
      _name.clear();
      _price.clear();
      _desc.clear();
      _qty.clear();
      _image = null;
      _selectedCategory = null; // <-- ADD THIS
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _saveProduct() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in the form.')),
      );
      return;
    }

    if (_image == null) {
      // ... (this check is unchanged) ...
    }

    // --- ADD CATEGORY VALIDATION ---
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product category.')),
      );
      return;
    }
    // --- END VALIDATION ---

    setState(() => _isSaving = true);

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(_image!.path);
      final permanentPath = '${appDir.path}/$fileName';
      final newImage = await _image!.copy(permanentPath);

      final thumbnailFile = await _createThumbnail(newImage);
      final thumbnailPath = thumbnailFile?.path;

      final repository = ref.read(productRepositoryProvider);
      await repository.addProduct(
        name: _name.text,
        price: double.tryParse(_price.text) ?? 0.0,
        quantity: int.tryParse(_qty.text) ?? 0,
        description: _desc.text,
        category: _selectedCategory!, // <-- ADD THIS
        imagePath: newImage.path,
        thumbnailPath: thumbnailPath,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved!')),
      );

      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving product: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  InputDecoration _modernInputDecoration(String label) {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: _modernInputDecoration('Product Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // --- NEW CATEGORY DROPDOWN ---
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _modernInputDecoration('Category').copyWith(
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: [
                      ..._categories.map((cat) => DropdownMenuItem(
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
                          _loadCategories(); // Refresh list
                          setState(() {
                            _selectedCategory = newCategory;
                          });
                        }
                      } else {
                        setState(() => _selectedCategory = value);
                      }
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please select a category'
                        : null,
                  ),
                  // --- END CATEGORY DROPDOWN ---

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _price,
                    decoration: _modernInputDecoration('Price'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _qty,
                    decoration: _modernInputDecoration('Quantity'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (int.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    // ... (this widget is unchanged) ...
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                        colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      child: _image == null
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 50, color: colorScheme.outline),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to select image',
                            style: TextStyle(
                              color: colorScheme.outline,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _desc,
                    decoration: _modernInputDecoration('Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveProduct,
                      icon: _isSaving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save Product',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}