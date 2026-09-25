import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: SearchScreen(),
));

class Product {
  final int id;
  final String title, category, description, brand, thumbnail;
  final double price;

  Product({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.brand,
    required this.thumbnail,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> j) {
    return Product(
      id: j['id'] ?? 0,
      title: j['title'] ?? 'Sin nombre',
      category: j['category'] ?? 'Sin categoría',
      description: j['description'] ?? '',
      brand: j['brand'] ?? 'Sin marca',
      thumbnail: j['thumbnail'] ?? '',
      price: (j['price'] ?? 0).toDouble(),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final buscador = TextEditingController();
  List<Product> productos = [];
  bool cargando = false;
  String mensaje = '';

  Future<void> buscar() async {
    if (buscador.text.trim().isEmpty) return;

    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      final url = Uri.parse(
        'https://dummyjson.com/products/search?q='
        '${Uri.encodeQueryComponent(buscador.text)}&limit=20',
      );

      final r = await http.get(url);

      if (r.statusCode != 200) {
        throw Exception();
      }

      final datos = jsonDecode(r.body);
      productos = (datos['products'] as List)
          .map((p) => Product.fromJson(p))
          .toList();

      setState(() {
        cargando = false;
        if (productos.isEmpty) mensaje = 'No hay resultados.';
      });
    } catch (e) {
      setState(() {
        cargando = false;
        mensaje = 'No hay conexión a internet.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffffafa),
      appBar: AppBar(
        title: const Text(
          'Buscador de productos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff984d48),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: buscador,
                    onSubmitted: (_) => buscar(),
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          buscador.clear();
                          setState(() {
                            productos = [];
                            mensaje = '';
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: cargando ? null : buscar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff984d48),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),

          if (buscador.text.isNotEmpty && productos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${productos.length} resultado(s) para "${buscador.text}"',
                ),
              ),
            ),

          const SizedBox(height: 5),

          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : mensaje.isNotEmpty
                    ? Center(child: Text(mensaje))
                    : ListView.builder(
                        itemCount: productos.length,
                        itemBuilder: (context, index) {
                          final p = productos[index];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            leading: SizedBox(
                              width: 40,
                              height: 50,
                              child: Image.network(
                                p.thumbnail,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                              ),
                            ),
                            title: Text(
                              p.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(p.category),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Bs ${(p.price * 6.96).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$us ${p.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetailScreen(producto: p),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final Product producto;

  const DetailScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        backgroundColor: const Color(0xff984d48),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Image.network(
            producto.thumbnail,
            height: 220,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 15),
          Text(
            producto.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text('Categoría: ${producto.category}'),
          Text('Marca: ${producto.brand}'),
          const SizedBox(height: 10),
          Text(
            'Bs ${(producto.price * 6.96).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text('\$us ${producto.price.toStringAsFixed(2)}'),
          const SizedBox(height: 15),
          Text(producto.description),
        ],
      ),
    );
  }
}