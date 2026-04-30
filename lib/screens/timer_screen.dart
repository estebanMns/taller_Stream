import 'package:flutter/material.dart';
import '../blocs/timer_bloc.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final TimerBloc _timerBloc = TimerBloc();

  @override
  void dispose() {
    _timerBloc.dispose();
    super.dispose();
  }

  Future<void> _showSetTimeDialog() async {
    final TextEditingController hoursController = TextEditingController(text: '0');
    final TextEditingController minutesController = TextEditingController(text: '0');
    final TextEditingController secondsController = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Configurar Tiempo'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Hrs'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: secondsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Seg'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final h = int.tryParse(hoursController.text) ?? 0;
                final m = int.tryParse(minutesController.text) ?? 0;
                final s = int.tryParse(secondsController.text) ?? 0;
                _timerBloc.setTime(h, m, s);
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temporizador HIIT'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Obtener de API',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Obteniendo tiempo...')),
              );
              await _timerBloc.fetchTimeFromApi();
            },
          ),
          IconButton(
            icon: const Icon(Icons.timer),
            tooltip: 'Configurar Tiempo',
            onPressed: _showSetTimeDialog,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Contenedor principal con el indicador de progreso y el texto
            Stack(
              alignment: Alignment.center,
              children: [
                // Widget 1: Indicador de progreso circular (escucha el stream)
                SizedBox(
                  width: 250,
                  height: 250,
                  child: StreamBuilder<int>(
                    stream: _timerBloc.timeStream,
                    initialData: _timerBloc.initialTime,
                    builder: (context, snapshot) {
                      final time = snapshot.data ?? 0;
                      final initTime = _timerBloc.initialTime;
                      // Calculamos el porcentaje restante (evitando division por cero)
                      final progress = initTime > 0 ? time / initTime : 0.0;

                      return CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.deepPurple.shade100,
                        color: Colors.deepPurple,
                      );
                    },
                  ),
                ),
                // Widget 2: Texto de los minutos/segundos (escucha el MISMO stream)
                StreamBuilder<int>(
                  stream: _timerBloc.timeStream,
                  initialData: _timerBloc.initialTime,
                  builder: (context, snapshot) {
                    final time = snapshot.data ?? 0;

                    // Formateamos para que se vea como hh:mm:ss o mm:ss
                    final hours = (time ~/ 3600).toString().padLeft(2, '0');
                    final minutes = ((time % 3600) ~/ 60).toString().padLeft(2, '0');
                    final seconds = (time % 60).toString().padLeft(2, '0');

                    final timeString = time >= 3600 
                        ? '$hours:$minutes:$seconds' 
                        : '$minutes:$seconds';

                    return Text(
                      timeString,
                      style: TextStyle(
                        fontSize: time >= 3600 ? 48 : 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 50),
            // Botones de control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _timerBloc.startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _timerBloc.pauseTimer,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pausar'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _timerBloc.resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
