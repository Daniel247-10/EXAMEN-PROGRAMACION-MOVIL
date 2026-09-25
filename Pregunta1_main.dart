import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buscador de productos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SearchScreen(),
    );
  }
}

// ============================================================
// CAPA DE MODELO
// ============================================================

class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String thumbnail;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.thumbnail,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _asInt(json['id']),
      title: _asString(json['title'], fallback: 'Sin nombre'),
      description: _asString(json['description'], fallback: ''),
      category: _asString(json['category'], fallback: 'Sin categoría'),
      price: _asDouble(json['price']),
      discountPercentage: _asDouble(json['discountPercentage']),
      rating: _asDouble(json['rating']),
      stock: _asInt(json['stock']),
      brand: _asString(json['brand'], fallback: 'Sin marca'),
      thumbnail: _asString(json['thumbnail'], fallback: ''),
    );
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }
}

// ============================================================
// CAPA DE SERVICIO
// ============================================================

class ProductServiceException implements Exception {
  final String message;
  ProductServiceException(this.message);
}

class ProductService {
  static const String _baseUrl = 'https://dummyjson.com/products/search';

  Future<List<Product>> searchProducts(String query, {int limit = 20}) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': query,
      'limit': limit.toString(),
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ProductServiceException(
          'Error del servidor (${response.statusCode}).',
        );
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> rawProducts =
          body['products'] is List ? body['products'] as List<dynamic> : const [];

      return rawProducts
          .whereType<Map<String, dynamic>>()
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (e) {
      throw ProductServiceException(
        'No hay conexión a internet o el servidor no respondió.',
      );
    }
  }
}

// ============================================================
// CAPA DE PRESENTACIÓN
// ============================================================

enum _ViewState { inicial, cargando, exito, vacio, error }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ProductService _service = ProductService();
  final TextEditingController _controller = TextEditingController();

  _ViewState _state = _ViewState.inicial;
  List<Product> _products = [];
  String _errorMessage = '';

  Future<void> _buscar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _state = _ViewState.cargando);

    try {
      final resultados = await _service.searchProducts(texto);
      setState(() {
        _products = resultados;
        _state = resultados.isEmpty ? _ViewState.vacio : _ViewState.exito;
      });
    } on ProductServiceException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _state = _ViewState.error;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscador de Productos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Buscar productos...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _buscar(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _buscar,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContenido()),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    switch (_state) {
      case _ViewState.inicial:
        return const Center(child: Text('Comienza buscando un producto.'));
      case _ViewState.cargando:
        return const Center(child: CircularProgressIndicator());
      case _ViewState.vacio:
        return const Center(child: Text('No hay resultados.'));
      case _ViewState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(_errorMessage),
              TextButton(onPressed: _buscar, child: const Text('Intentar de nuevo')),
            ],
          ),
        );
      case _ViewState.exito:
        return ListView.builder(
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final p = _products[index];
            return ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(p.thumbnail)),
              title: Text(p.title),
              subtitle: Text('\$${p.price.toStringAsFixed(2)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
            );
          },
        );
    }
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  void _copyToClipboard(BuildContext context) {
    final text = '${product.title} - \$${product.price}';
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copiado: $text'), duration: const Duration(seconds: 2)),
        );
      }
    }).catchError((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al copiar al portapapeles.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Image.network(product.thumbnail, height: 250, fit: BoxFit.contain),
          const SizedBox(height: 16),
          Text(product.title, style: Theme.of(context).textTheme.headlineSmall),
          ListTile(
            title: const Text('Precio'),
            subtitle: Text('\$${product.price}'),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyToClipboard(context),
            ),
          ),
          ListTile(title: const Text('Marca'), subtitle: Text(product.brand)),
          ListTile(title: const Text('Descripción'), subtitle: Text(product.description)),
        ],
      ),
    );
  }
}