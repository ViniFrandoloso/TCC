import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'Mapa.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List<Map<String, dynamic>> _pages = [
    {'page': Home(), 'title': 'Home', 'icon': Icons.home,},
    {'page': Mapa(), 'title': 'Mapa', 'icon': Icons.map},
  ];

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if(_pages[_selectedIndex]['title'] == 'Mapa' ){
      _adicionarLocal();
    }
  }

  final StreamController<QuerySnapshot> _controller =
  StreamController<QuerySnapshot>.broadcast();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _abrirMapa(String idViagem) {
    print("ID Viagem: " + idViagem);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Mapa(
          idViagem: idViagem,
        ),
      ),
    );
  }

  Future<void> _excluirViagem(String idViagem) async {
    await _db.collection("viagens").doc(idViagem).delete();
  }

  void _adicionarLocal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Mapa(),
      ),
    );
  }

  void _adicionarListenerViagens() {
    final Stream<QuerySnapshot> stream = _db.collection("viagens").snapshots();

    stream.listen((QuerySnapshot dados) {
      _controller.add(dados);
    });
  }

  @override
  void initState() {
    super.initState();

    _adicionarListenerViagens();
  }

  @override
  void dispose() {
    _controller.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Localização"),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.home),
            ),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.map),
            ),
            label: 'Mapa',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),


      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final QuerySnapshot querySnapshot = snapshot.data!;
          final List<QueryDocumentSnapshot> viagens = querySnapshot.docs;

          return Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  itemCount: viagens.length,
                  itemBuilder: (_, int index) {
                    final QueryDocumentSnapshot item = viagens[index];
                    final String titulo = item["titulo"] as String;
                    final String idViagem = item.id;

                    return GestureDetector(
                      onTap: () => _abrirMapa(idViagem),
                      child: Card(
                        child: ListTile(
                          title: Text(titulo),
                          trailing: GestureDetector(
                            onTap: () => _excluirViagem(idViagem),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}