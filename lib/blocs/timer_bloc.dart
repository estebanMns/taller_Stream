import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TimerBloc {
  int _initialTime = 3600;
  int _currentTime;
  Timer? _timer;

  // StreamController para el tiempo restante.
  // Usamos .broadcast() para que múltiples widgets (texto, círculo de progreso)
  // puedan escuchar el mismo flujo de datos simultáneamente.
  final _timeController = StreamController<int>.broadcast();

  // Stream al que se suscribirá la UI
  Stream<int> get timeStream => _timeController.stream;

  TimerBloc() : _currentTime = 3600 {
    // Emitimos el valor inicial
    _timeController.sink.add(_currentTime);
  }

  // Método para obtener el tiempo inicial y calcular porcentajes
  int get initialTime => _initialTime;


  void setTime(int hours, int minutes, int seconds) {
    _timer?.cancel();
    _initialTime = (hours * 3600) + (minutes * 60) + seconds;
    _currentTime = _initialTime;
    _timeController.sink.add(_currentTime);
  }

  // Obtiene el tiempo (en segundos) simulando una llamada a un API.
  Future<void> fetchTimeFromApi() async {
    try {
      // Usamos dummyjson.com porque tiene soporte para CORS en Flutter Web
      final url = Uri.parse('https://dummyjson.com/products/1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Obtenemos el precio del producto y lo usamos como segundos (ej. 549 segundos)
        // Puedes cambiar esto por el campo de tu API real.
        final int apiTime = (data['price'] as num).toInt();
        
        _timer?.cancel();
        _initialTime = apiTime;
        _currentTime = _initialTime;
        _timeController.sink.add(_currentTime);
      } else {
        print('Error en la petición: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al consultar el API: $e');
    }
  }

  void startTimer() {
    if (_timer != null && _timer!.isActive) return; // Evita múltiples timers simultáneos

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTime > 0) {
        _currentTime--;
        // Emitimos el nuevo valor cada segundo
        _timeController.sink.add(_currentTime);
      } else {
        // El temporizador llegó a 0
        timer.cancel();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
  }

  void resetTimer() {
    _timer?.cancel();
    _currentTime = _initialTime;
    _timeController.sink.add(_currentTime); // Emitimos el valor restaurado
  }

  // Limpieza de recursos (evita memory leaks)
  void dispose() {
    _timer?.cancel();
    _timeController.close();
  }
}
