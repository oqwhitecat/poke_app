import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
      ),
      home: const PokemonListScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// หน้าที่ 1: รายการโปเกม่อน (Load More + สลับ View + Hero)
// -----------------------------------------------------------------------------
class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  List<dynamic> pokemons = [];
  String? nextUrl = 'https://pokeapi.co/api/v2/pokemon?limit=20';
  bool isLoading = false;
  bool isGridView = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    getData();
    
    // ปรับ Load More ให้เริ่มโหลดก่อนถึงล่างสุด 200 pixels เพื่อความลื่นไหล
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!isLoading && nextUrl != null) {
          getData();
        }
      }
    });
  }

  Future<void> getData() async {
    if (nextUrl == null) return;
    
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(nextUrl!));
      final jsonData = jsonDecode(response.body);
      setState(() {
        pokemons.addAll(jsonData['results']);
        nextUrl = jsonData['next'];
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  String getPokemonId(String url) {
    return url.split('/')[url.split('/').length - 2];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PokeAPI - Pokedex', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => isGridView = !isGridView),
            tooltip: 'สลับรูปแบบการแสดงผล',
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isGridView ? _buildGrid() : _buildList(),
          ),
          if (isLoading) 
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: pokemons.length,
      itemBuilder: (context, index) => _pokemonCard(pokemons[index]),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
      ),
      itemCount: pokemons.length,
      itemBuilder: (context, index) => _pokemonCard(pokemons[index]),
    );
  }

  Widget _pokemonCard(dynamic pokemon) {
    final id = getPokemonId(pokemon['url']);
    final imgUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600), // ปรับให้ลอยช้าลงเล็กน้อยเพื่อให้เห็นชัด
            pageBuilder: (context, animation, secondaryAnimation) => 
              PokemonDetailScreen(name: pokemon['name'], url: pokemon['url'], imgUrl: imgUrl, id: id),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'pokemon-img-$id', // Tag ต้องเหมือนกันเป๊ะ
              child: Image.network(
                imgUrl, 
                height: isGridView ? 100 : 80,
                fit: BoxFit.contain, // สำคัญ: เพื่อให้การลอยไม่กระตุก
                errorBuilder: (c, e, s) => const Icon(Icons.catching_pokemon, size: 50),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '#$id',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              pokemon['name'].toString().toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// หน้าที่ 2: รายละเอียด (Hero Animation ลอยสวย + ข้อมูลครบ)
// -----------------------------------------------------------------------------
class PokemonDetailScreen extends StatefulWidget {
  final String name, url, imgUrl, id;
  const PokemonDetailScreen({super.key, required this.name, required this.url, required this.imgUrl, required this.id});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  Map<String, dynamic>? details;
  bool isDetailLoading = true;

  @override
  void initState() {
    super.initState();
    getExtraData();
  }

  Future<void> getExtraData() async {
    try {
      final res = await http.get(Uri.parse(widget.url));
      if (mounted) {
        setState(() {
          details = jsonDecode(res.body);
          isDetailLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isDetailLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วนแสดงรูปภาพ (Hero)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Center(
                child: Hero(
                  tag: 'pokemon-img-${widget.id}', // Tag ตรงกับหน้าแรก
                  child: Image.network(
                    widget.imgUrl,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // ข้อมูลรายละเอียด
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    widget.name.toUpperCase(),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Number: #${widget.id}',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  
                  if (isDetailLoading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    )
                  else if (details != null) ...[
                    // ข้อมูล Height, Weight
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _infoItem('Height', '${details!['height'] / 10} m'),
                        _infoItem('Weight', '${details!['weight'] / 10} kg'),
                      ],
                    ),
                    const SizedBox(height: 25),
                    
                    // ข้อมูล Types
                    const Text('Types', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: (details!['types'] as List).map((t) => Chip(
                        label: Text(
                          t['type']['name'].toString().toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.orangeAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}