import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const PostPage(),
  ),
);

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final titulo = TextEditingController();
  final cuerpo = TextEditingController();
  final usuario = TextEditingController(text: '1');

  bool enviando = false;
  String mensaje = '';
  int? id;

  Future<void> publicar() async {
    if (titulo.text.isEmpty || cuerpo.text.isEmpty || usuario.text.isEmpty) {
      setState(() => mensaje = 'Complete todos los campos');
      return;
    }

    int? userId = int.tryParse(usuario.text);

    if (userId == null || userId < 1 || userId > 100) {
      setState(() => mensaje = 'El ID debe ser un número entre 1 y 100');
      return;
    }

    setState(() {
      enviando = true;
      mensaje = 'Enviando publicación...';
    });

    try {
      final respuesta = await http.post(
        Uri.parse('https://dummyjson.com/posts/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': titulo.text,
          'body': cuerpo.text,
          'userId': userId,
        }),
      );

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final datos = jsonDecode(respuesta.body);

        setState(() {
          id = datos['id'];
          mensaje = 'Publicación registrada';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Publicación creada con el ID $id'),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        setState(() => mensaje =
            'No se pudo registrar. Error ${respuesta.statusCode}');
      }
    } catch (e) {
      setState(() => mensaje = 'No se pudo conectar con el servidor');
    }

    setState(() => enviando = false);
  }

  void limpiar() {
    titulo.clear();
    cuerpo.clear();
    usuario.text = '1';
    setState(() {
      mensaje = '';
      id = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffdf7f6),
      appBar: AppBar(
        title: const Text('POST /posts/add'),
        backgroundColor: const Color(0xfffdf7f6),
        foregroundColor: Colors.indigo,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [

            TextField(
              controller: titulo,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: cuerpo,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Contenido',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: usuario,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Id del autor',
                border: OutlineInputBorder(),
                helperText: 'Un número entre 1 y 100',
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: enviando ? null : publicar,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  enviando
                      ? 'Enviando...'
                      : 'Registrar publicación',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff9d4f49),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            if (mensaje.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: id != null
                      ? const Color(0xffe7f5f2)
                      : const Color(0xffffeaea),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: id != null ? Colors.teal : Colors.red,
                  ),
                ),
                child: Text(
                  id != null
                      ? '✓  Publicación registrada\n\n'
                          'El servidor asignó el identificador $id a "${titulo.text}".'
                      : mensaje,
                  style: TextStyle(
                    color: id != null ? Colors.teal : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            if (id != null)
              TextButton(
                onPressed: limpiar,
                child: const Text('Limpiar formulario'),
              ),
          ],
        ),
      ),
    );
  }
}