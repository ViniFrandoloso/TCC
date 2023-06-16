import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'Home.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Mapa extends StatefulWidget {
  String? idViagem;

  Mapa({this.idViagem});

  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  var cont = 0;

  List<Map<String, dynamic>> _pages = [
    {
      'page': Home(),
      'title': 'Início',
      'icon': Icons.home,
    },
    {'page': Mapa(), 'title': 'Mapa', 'icon': Icons.map},
    {'title': 'Recuperar', 'icon': Icons.devices_outlined}
  ];

  final String fileName = 'coletaSemEstacionarUltima.txt';

  var _val = 0;

  late File _file;

  int _selectedIndex = 1;

  late Timer _timer;

  late GyroscopeEvent? _giroscopio;

  late MagnetometerEvent? _magnetometro;

  Position? posicaoAtual = null;

  double _velocidadeAtual = 0.0;

  String filePath = '';

  String mensagemTela = 'Contagem Parada';

  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _marcadores = {};
  CameraPosition _posicaoCamera =
      CameraPosition(target: LatLng(-23.562436, -46.655005), zoom: 18);
  FirebaseFirestore _db = FirebaseFirestore.instance;

  _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (_pages[_selectedIndex]['title'] == 'Início') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => _pages[_selectedIndex]['page']),
      );
    } else if (_pages[_selectedIndex]['title'] == 'Recuperar') {
      _recuperarDados();
    }
  }

  /*_adicionarMarcador(LatLng latLng) async {
    List<Placemark> listaEnderecos = await Geolocator()
        .placemarkFromCoordinates(latLng.latitude, latLng.longitude);

    if (listaEnderecos != null && listaEnderecos.length > 0) {
      Placemark endereco = listaEnderecos[0];
      String rua = endereco.thoroughfare;

      //41.890250, 12.492242
      Marker marcador = Marker(
          markerId: MarkerId("marcador-${latLng.latitude}-${latLng.longitude}"),
          position: latLng,
          infoWindow: InfoWindow(title: rua));

      setState(() {
        _marcadores.add(marcador);

        //Salva no firebase
        Map<String, dynamic> viagem = Map();
        viagem["titulo"] = rua;
        viagem["latitude"] = latLng.latitude;
        viagem["longitude"] = latLng.longitude;

        _db.collection("viagens").add(viagem);
      });
    }
  }

   */

  _movimentarCamera() async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(_posicaoCamera));
  }

  _adicionarListenerLocalizacao() {
    //-23.579934, -46.660715

    var geolocator = Geolocator();

    Geolocator.getPositionStream(
            locationSettings: LocationSettings(accuracy: LocationAccuracy.best))
        .listen((Position position) {
      setState(() {
        posicaoAtual = position;
        _posicaoCamera = CameraPosition(
            target: LatLng(position.latitude, position.longitude), zoom: 18);

        _velocidadeAtual = position.speed ?? 0.0; //atualiza a velocidade
        _velocidadeAtual = _velocidadeAtual * 3.6; //transformando a velocidade para km/h

        // Capturando dados do giroscópio
        gyroscopeEvents.listen((GyroscopeEvent event) {
          _giroscopio = event;
        });

        // Capturando dados do magnetômetro
        magnetometerEvents.listen((MagnetometerEvent event) {
          _magnetometro = event;
        });

        _movimentarCamera();
      });
    });
  }

  _recuperaViagemParaID(String? idViagem) async {
    if (idViagem != null) {
      //exibir marcador para id viagem
      DocumentSnapshot documentSnapshot =
          await _db.collection("viagens").doc(idViagem).get();

      print(documentSnapshot.data());

      var dados = documentSnapshot.data() as Map;

      String titulo = dados["titulo"];
      LatLng latLng = LatLng(dados["latitude"], dados["longitude"]);

      print("Latitude: ${latLng.latitude}");
      print("Longitude: ${latLng.longitude}");

      setState(() {
        Marker marcador = Marker(
            markerId:
                MarkerId("marcador-${latLng.latitude}-${latLng.longitude}"),
            position: latLng,
            infoWindow: InfoWindow(title: titulo));

        _marcadores.add(marcador);
        _posicaoCamera = CameraPosition(target: latLng, zoom: 18);
        _movimentarCamera();
      });
    } else {
      _adicionarListenerLocalizacao();
    }
  }

  Future<String> getFilePath() async {
    final directory = await getExternalStorageDirectory();
    return '${directory?.path}/$fileName';
  }

  void _coletarDados() async {
    setState(() {
      mensagemTela = "Coleta Iniciada";
    });
    Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      filePath = directory.path + '/$fileName';
    }

    _timer = Timer.periodic(Duration(milliseconds: 500), _salvarDados);
    Timer(Duration(seconds: 60), _finalizarColeta);
  }

  Future<void> _salvarDados(Timer timer) async {
    File file = File(filePath);

    List<String> listaDeValores = [];
    try {
      if (file.lengthSync() == 0) {
      } else {
      }
    } catch (e) {
      String data;
      data =
          "Velocidade, Latitude, Longitude, Giroscopio (X), Giroscopio (Y), Giroscopio (Z), Magnetometro (X), Magnetometro (Y), Magnetometro (Z)\n";
      listaDeValores.add(data);
      IOSink sink = file.openWrite(mode: FileMode.append);
      sink.writeAll(listaDeValores);
      sink.close();
    }
    String data = "$_velocidadeAtual";
    if (posicaoAtual != null) {
      data += ", ${posicaoAtual?.latitude}, ${posicaoAtual?.longitude}";
    }
    if (_giroscopio != null) {
      data += ", ${_giroscopio?.x}, ${_giroscopio?.y}, ${_giroscopio?.z}";
    }
    if (_magnetometro != null) {
      data +=
          ", ${_magnetometro?.x}, ${_magnetometro?.y}, ${_magnetometro?.z}\n";
    }

    listaDeValores.add(data);

    // salvar os dados em um arquivo TXT
    IOSink sink = file.openWrite(mode: FileMode.append);
    sink.writeAll(listaDeValores, '\n');
    sink.close();
  }

  _finalizarColeta() {
    List<String> listaDeValores = [];
    String data = "\n";
    File file = File(filePath);
    IOSink sink = file.openWrite(mode: FileMode.append);
    listaDeValores.add(data);
    sink.writeAll(listaDeValores, "\n");
    sink.close();

    _timer.cancel();
    setState(() {
      mensagemTela = "Coleta Finalizada";
    });
    print("Coleta Finalizada");
  }

  _recuperarDados() async {
    Directory? directory = await getExternalStorageDirectory();

    final String _filePath = await getFilePath();
    final File file = File(_filePath);
    final String content = await file.readAsString();
    //file.delete();

    print(directory);
    print(content);
  }

  @override
  void initState() {
    _adicionarListenerLocalizacao();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mapa"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _coletarDados,
        child: Icon(Icons.check_box),
        tooltip: 'Coletar',
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices_outlined),
            label: 'Recuperar',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              markers: _marcadores,
              mapType: MapType.normal,
              initialCameraPosition: _posicaoCamera,
              myLocationEnabled: true,
              onMapCreated: _onMapCreated,
            ),
          ),
          Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.speed),
                      SizedBox(width: 8),
                      Text(
                        _velocidadeAtual.toStringAsFixed(2),
                        style: TextStyle(fontSize: 24),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "km/h",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sort_by_alpha),
                        SizedBox(width: 8),
                        Text(
                          mensagemTela,
                          style: TextStyle(fontSize: 15),
                        ),
                        SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
