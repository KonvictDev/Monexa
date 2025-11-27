import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../../repositories/product_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../services/gating_service.dart';
import '../../utils/constants.dart';

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

  // Initialized empty to prevent null errors before load
  List<String> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    // Fetch latest categories from Hive
    final loaded = ref.read(settingsRepositoryProvider).getProductCategories();
    setState(() {
      _categories = loaded;
    });
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

  // --- IMAGE LOGIC START ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Optimized for performance
        maxWidth: 1024,   // Resize large camera photos
      );

      if (picked != null) {
        setState(() => _image = File(picked.path));
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      // Optional: Show a snackbar if permission is denied
    }
  }

  void _showImageSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<File?> _createThumbnail(File originalImage) async {
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
  // --- IMAGE LOGIC END ---

  void _resetForm() {
    setState(() {
      _name.clear();
      _price.clear();
      _desc.clear();
      _qty.clear();
      _image = null;
      _selectedCategory = null;
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

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product category.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(productRepositoryProvider);

      String imagePath = '';
      String? thumbnailPath;

      // Handle Image Saving
      if (_image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(_image!.path);
        final permanentPath = '${appDir.path}/$fileName';

        // Copy to app storage
        final newImage = await _image!.copy(permanentPath);
        imagePath = newImage.path;

        // Generate Thumbnail
        final thumbnailFile = await _createThumbnail(newImage);
        thumbnailPath = thumbnailFile?.path;
      }

      await repository.addProduct(
        name: _name.text,
        price: double.tryParse(_price.text) ?? 0.0,
        quantity: int.tryParse(_qty.text) ?? 0,
        description: _desc.text,
        category: _selectedCategory!,
        imagePath: imagePath,
        thumbnailPath: thumbnailPath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product saved!')),
        );
      }
      _resetForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _modernInputDecoration(String label) {
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
    final canCustomizeCategory = ref.watch(gatingServiceProvider).canAccessFeature(Feature.categoryCustomization);

    // 🔥 FIX FOR CRASH: PREPARE CATEGORY LIST SAFELY
    // 1. Create a copy of the categories
    Set<String> safeCategories = Set.from(_categories);

    // 2. If _selectedCategory has a value (e.g. 'yvg') that isn't in the list,
    // add it temporarily so the Dropdown doesn't crash.
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      safeCategories.add(_selectedCategory!);
    }

    // 3. Convert back to list for the UI
    final dropdownItems = safeCategories.toList();


    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

                  // --- CATEGORY DROPDOWN ---
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _modernInputDecoration('Category').copyWith(
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: [
                      ...dropdownItems.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      )),
                      // Gated "Add New" Logic
                      if (canCustomizeCategory)
                        const DropdownMenuItem(
                          value: 'ADD_NEW',
                          child: Row(
                            children: [
                              Icon(Icons.add, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Add new category'),
                            ],
                          ),
                        )
                      else
                        const DropdownMenuItem(
                          value: 'LOCKED',
                          enabled: false,
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Pro required to add category'),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) async {
                      if (value == 'ADD_NEW') {
                        final newCategory = await _showAddCategoryDialog(context);
                        if (newCategory != null && newCategory.isNotEmpty) {
                          await ref.read(settingsRepositoryProvider).addProductCategory(newCategory);
                          _loadCategories(); // Refresh list from repo
                          setState(() {
                            _selectedCategory = newCategory;
                          });
                        }
                      } else {
                        setState(() => _selectedCategory = value);
                      }
                    },
                    validator: (value) =>
                    value == null || value.isEmpty || value == 'LOCKED'
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

                  // --- IMAGE PICKER ---
                  GestureDetector(
                    onTap: () => _showImageSourceModal(context),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      child: _image == null
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 50, color: colorScheme.outline),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add image',
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

                  // --- SAVE BUTTON ---
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