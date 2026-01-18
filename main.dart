import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: AkulkeysFinal()));

enum Nivel { basico, militar }

class Activo {
  final String titulo;
  final String clave;
  final Nivel nivel;
  Activo({required this.titulo, required this.clave, required this.nivel});
}

class AkulkeysFinal extends StatefulWidget {
  const AkulkeysFinal({super.key});
  @override
  State<AkulkeysFinal> createState() => _AkulkeysFinalState();
}

class _AkulkeysFinalState extends State<AkulkeysFinal> {
  bool _bloqueado = true;
  bool _escaneando = false;
  Nivel _seguridadActual = Nivel.basico;
  int _seccionActiva = 0;
  
  final _ctrlTitulo = TextEditingController();
  final _ctrlClave = TextEditingController();
  final List<Activo> _boveda = [
    Activo(titulo: "ACCESO MAESTRO", clave: "ak_root_2026", nivel: Nivel.basico)
  ];
  final List<String> _historial = ["sistema akulkeys iniciado"];

  void _registrarEvento(String msg) {
    setState(() => _historial.insert(0, "[${DateTime.now().hour}:${DateTime.now().minute}] $msg"));
  }

  void _iniciarAcceso() async {
    setState(() => _escaneando = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _escaneando = false;
      _bloqueado = false;
    });
    _registrarEvento("acceso biométrico confirmado");
  }

  void _generarClave() {
    String chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    int largo = 12;
    if (_seguridadActual == Nivel.militar) {
      chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#\$%^&*()_+-=[]{}';
      largo = 32;
    }
    setState(() => _ctrlClave.text = List.generate(largo, (i) => chars[Random().nextInt(chars.length)]).join());
    _registrarEvento("nueva clave generada");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020202),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _bloqueado ? _buildPortada() : _buildCuerpo(),
      ),
    );
  }

  Widget _buildPortada() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("akulkeys", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w100, letterSpacing: 18)),
          const SizedBox(height: 100),
          GestureDetector(
            onTap: _escaneando ? null : _iniciarAcceso,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.05))),
                  child: Icon(Icons.fingerprint, size: 50, color: _escaneando ? Colors.cyanAccent : Colors.white10),
                ),
                if (_escaneando) const _LineaEscaner(),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(_escaneando ? "verificando identidad..." : "toque para acceder", 
            style: TextStyle(color: _escaneando ? Colors.cyanAccent : Colors.white10, fontSize: 9, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildCuerpo() {
    bool esMilitar = _seguridadActual == Nivel.militar;
    Color colorTema = esMilitar ? Colors.redAccent : Colors.cyanAccent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text("akulkeys", style: TextStyle(letterSpacing: 8, fontSize: 14, color: Colors.white)),
        actions: [
          Switch(
            value: esMilitar,
            activeColor: Colors.redAccent,
            onChanged: (v) {
              setState(() => _seguridadActual = v ? Nivel.militar : Nivel.basico);
              _registrarEvento("cambio de nivel: ${v ? 'militar' : 'básico'}");
            },
          )
        ],
      ),
      body: Column(
        children: [
          _barraEstado(colorTema),
          Expanded(child: _buildSeccion(colorTema)),
        ],
      ),
      bottomNavigationBar: _buildNav(colorTema),
    );
  }

  Widget _barraEstado(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_seguridadActual == Nivel.militar ? "NIVEL: CRÍTICO" : "NIVEL: BÁSICO", style: TextStyle(color: color, fontSize: 8, letterSpacing: 1)),
          IconButton(icon: const Icon(Icons.power_settings_new, size: 14, color: Colors.white24), onPressed: () => setState(() => _bloqueado = true)),
        ],
      ),
    );
  }

  Widget _buildSeccion(Color color) {
    if (_seccionActiva == 0) return _vistaBoveda(color);
    if (_seccionActiva == 1) return _vistaGenerador(color);
    return _vistaAuditoria(color);
  }

  Widget _vistaBoveda(Color color) {
    var lista = _boveda.where((a) => a.nivel == _seguridadActual).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(25),
      itemCount: lista.length,
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => _mostrarClave(lista[i], color),
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.01), border: Border(left: BorderSide(color: color, width: 1))),
          child: Row(
            children: [
              Text(lista[i].titulo, style: const TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 2)),
              const Spacer(),
              Icon(Icons.chevron_right, size: 14, color: color.withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarClave(Activo activo, Color color) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF050505),
      shape: const RoundedRectangleBorder(),
      title: Text(activo.titulo, style: const TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 2)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          SelectableText(activo.clave, style: TextStyle(color: color, fontSize: 18, fontFamily: 'monospace', letterSpacing: 2)),
          const SizedBox(height: 30),
          TextButton(onPressed: () => Navigator.pop(context), child: Text("cerrar", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10)))
        ],
      ),
    ));
    _registrarEvento("salida de clave: ${activo.titulo}");
  }

  Widget _vistaGenerador(Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          TextField(controller: _ctrlTitulo, style: const TextStyle(color: Colors.white, fontSize: 13), decoration: InputDecoration(labelText: "servicio", labelStyle: TextStyle(color: color.withOpacity(0.3)))),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrlClave,
            style: TextStyle(color: color, fontSize: 16, fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: "clave",
              labelStyle: TextStyle(color: color.withOpacity(0.3)),
              suffixIcon: IconButton(icon: Icon(Icons.refresh, color: color), onPressed: _generarClave),
            ),
          ),
          const SizedBox(height: 50),
          OutlinedButton(
            style: OutlinedButton.styleFrom(side: BorderSide(color: color.withOpacity(0.5)), minimumSize: const Size(double.infinity, 50)),
            onPressed: () {
              if (_ctrlTitulo.text.isNotEmpty) {
                setState(() {
                  _boveda.add(Activo(titulo: _ctrlTitulo.text.toUpperCase(), clave: _ctrlClave.text, nivel: _seguridadActual));
                  _seccionActiva = 0;
                });
                _registrarEvento("nuevo registro sellado");
              }
            },
            child: Text("SELLAR", style: TextStyle(color: color, letterSpacing: 5, fontSize: 10)),
          )
        ],
      ),
    );
  }

  Widget _vistaAuditoria(Color color) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: _historial.map((e) => Text(e, style: TextStyle(color: color, fontSize: 9, fontFamily: 'monospace', height: 2))).toList(),
    );
  }

  Widget _buildNav(Color color) {
    return BottomNavigationBar(
      currentIndex: _seccionActiva,
      onTap: (i) => setState(() => _seccionActiva = i),
      backgroundColor: Colors.black,
      selectedItemColor: color,
      unselectedItemColor: Colors.white10,
      showSelectedLabels: false,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.lock_outline), label: ""),
        const BottomNavigationBarItem(icon: Icon(Icons.add), label: ""),
        if (_seguridadActual == Nivel.militar) const BottomNavigationBarItem(icon: Icon(Icons.terminal), label: ""),
      ],
    );
  }
}

class _LineaEscaner extends StatefulWidget {
  const _LineaEscaner();
  @override
  __LineaEscanerState createState() => __LineaEscanerState();
}

class __LineaEscanerState extends State<_LineaEscaner> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Positioned(
        top: 20 + (_c.value * 90),
        child: Container(
          width: 100, 
          height: 1, 
          // CORRECCIÓN: boxShadow movido dentro de BoxDecoration
          decoration: BoxDecoration(
            color: Colors.cyanAccent,
            boxShadow: [
              BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 10)
            ],
          ),
        ),
      ),
    );
  }
}