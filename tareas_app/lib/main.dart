import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tareas App',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D6A4F),
          primary: const Color(0xFF2D6A4F),
          secondary: const Color(0xFF52B788),
          surface: Colors.white,
          onSurface: const Color(0xFF1F2937),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2D6A4F), width: 1.5),
          ),
        ),
      ),
      home: const VerificadorSesion(),
    );
  }
}

// 1. COMPROBADOR DE TOKEN AL INICIAR
class VerificadorSesion extends StatefulWidget {
  const VerificadorSesion({super.key});

  @override
  State<VerificadorSesion> createState() => _VerificadorSesionState();
}

class _VerificadorSesionState extends State<VerificadorSesion> {
  bool comprobando = true;
  bool tieneToken = false;

  @override
  void initState() {
    super.initState();
    verificarToken();
  }

  Future<void> verificarToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    setState(() {
      tieneToken = token != null && token.isNotEmpty;
      comprobando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (comprobando) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    return tieneToken ? const PantallaTareas() : const PantallaAuth();
  }
}

// 2. PANTALLA DE AUTENTICACIÓN
class PantallaAuth extends StatefulWidget {
  const PantallaAuth({super.key});

  @override
  State<PantallaAuth> createState() => _PantallaAuthState();
}

class _PantallaAuthState extends State<PantallaAuth> {
  final TextEditingController usuarioCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final String baseUrl = 'http://127.0.0.1:8000/api';
  bool esLogin = true;
  bool cargando = false;

  Future<void> procesarAuth() async {
    final username = usuarioCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) return;

    setState(() => cargando = true);
    final endpoint = esLogin ? '/login/' : '/registro/';

    try {
      final respuesta = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final datos = json.decode(respuesta.body);
        final token = datos['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        // NUEVO: Guardamos el nombre de usuario para asociarle su contador único
        await prefs.setString('usuario_actual', username);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PantallaTareas()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${respuesta.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFD8F3DC),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                esLogin ? '¡Hola de nuevo!' : 'Crear Cuenta',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                esLogin
                    ? 'Ingresa tus datos para acceder a tus tareas'
                    : 'Regístrate para comenzar a organizarte',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: usuarioCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: cargando ? null : procesarAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: cargando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                esLogin ? 'Iniciar Sesión' : 'Registrarse',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => esLogin = !esLogin),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
                    children: [
                      TextSpan(
                        text: esLogin
                            ? '¿No tienes cuenta? '
                            : '¿Ya tienes cuenta? ',
                      ),
                      TextSpan(
                        text: esLogin ? 'Regístrate' : 'Inicia Sesión',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. PANTALLA DE TAREAS
class PantallaTareas extends StatefulWidget {
  const PantallaTareas({super.key});

  @override
  State<PantallaTareas> createState() => _PantallaTareasState();
}

class _PantallaTareasState extends State<PantallaTareas> {
  final String baseUrl = 'http://127.0.0.1:8000/api';
  List<dynamic> tareasHoy = [];
  bool cargando = false;
  int totalCompletadasAcumuladas = 0;

  @override
  void initState() {
    super.initState();
    _cargarContadorCompletadas();
    obtenerTareas();
  }

  // NUEVO: Carga el contador específico del usuario activo
  Future<void> _cargarContadorCompletadas() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioActual = prefs.getString('usuario_actual') ?? 'anonimo';
    final claveUsuario = 'tareas_completadas_$usuarioActual';

    setState(() {
      totalCompletadasAcumuladas = prefs.getInt(claveUsuario) ?? 0;
    });
  }

  // NUEVO: Incrementa únicamente el contador del usuario activo
  Future<void> _incrementarContadorCompletadas() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioActual = prefs.getString('usuario_actual') ?? 'anonimo';
    final claveUsuario = 'tareas_completadas_$usuarioActual';

    setState(() {
      totalCompletadasAcumuladas++;
    });
    await prefs.setInt(claveUsuario, totalCompletadasAcumuladas);
  }

  Future<String?> _obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> obtenerTareas() async {
    final token = await _obtenerToken();
    if (token == null) return;

    setState(() => cargando = true);
    try {
      final respuesta = await http.get(
        Uri.parse('$baseUrl/tareas/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (respuesta.statusCode == 200) {
        setState(() {
          tareasHoy = json.decode(respuesta.body);
        });
      }
    } catch (e) {
      debugPrint("Error al obtener tareas: $e");
    } finally {
      setState(() => cargando = false);
    }
  }

  Future<void> agregarTarea(String titulo, String descripcion) async {
    final token = await _obtenerToken();
    if (token == null) return;

    try {
      final respuesta = await http.post(
        Uri.parse('$baseUrl/tareas/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'titulo': titulo,
          'descripcion': descripcion,
        }),
      );

      if (respuesta.statusCode == 201) {
        obtenerTareas();
      }
    } catch (e) {
      debugPrint("Error al agregar tarea: $e");
    }
  }

  Future<void> completarTarea(int id) async {
    final token = await _obtenerToken();
    if (token == null) return;

    try {
      final respuesta = await http.post(
        Uri.parse('$baseUrl/tareas/$id/completar/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (respuesta.statusCode == 200) {
        await _incrementarContadorCompletadas();
        obtenerTareas();
      }
    } catch (e) {
      debugPrint("Error al completar: $e");
    }
  }

  Future<void> editarTarea(int id, String nuevoTitulo, String nuevaDescripcion) async {
    final token = await _obtenerToken();
    if (token == null) return;

    try {
      final respuesta = await http.patch(
        Uri.parse('$baseUrl/tareas/$id/editar/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'titulo': nuevoTitulo,
          'descripcion': nuevaDescripcion,
        }),
      );

      if (respuesta.statusCode == 200) {
        obtenerTareas();
      }
    } catch (e) {
      debugPrint("Error al editar: $e");
    }
  }

  Future<void> eliminarTarea(int id) async {
    final token = await _obtenerToken();
    if (token == null) return;

    try {
      final respuesta = await http.delete(
        Uri.parse('$baseUrl/tareas/$id/eliminar/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (respuesta.statusCode == 204) {
        obtenerTareas();
      }
    } catch (e) {
      debugPrint("Error al eliminar: $e");
    }
  }

  // NUEVO: Limpiamos token y usuario_actual al cerrar sesión
  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('usuario_actual');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PantallaAuth()),
      );
    }
  }

  void mostrarDialogoNuevaTarea() {
    final controllerTitulo = TextEditingController();
    final controllerDesc = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Centramos el título del diálogo
          title: const Text(
            'Nueva Tarea',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controllerTitulo,
                decoration: const InputDecoration(hintText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controllerDesc,
                decoration: const InputDecoration(hintText: 'Descripción (Opcional)'),
              ),
            ],
          ),
          // Centramos las acciones dentro del diálogo
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (controllerTitulo.text.trim().isNotEmpty) {
                  agregarTarea(
                    controllerTitulo.text.trim(),
                    controllerDesc.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void mostrarDialogoEditarTarea(Map<String, dynamic> tarea) {
    final String tituloInicial = tarea['titulo'] ?? '';
    final String descInicial = tarea['descripcion'] ?? '';

    final controllerTitulo = TextEditingController(text: tituloInicial);
    final controllerDesc = TextEditingController(text: descInicial);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Centramos el título del diálogo
          title: const Text(
            'Editar Tarea',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controllerTitulo,
                decoration: const InputDecoration(hintText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controllerDesc,
                decoration: const InputDecoration(hintText: 'Descripción'),
              ),
            ],
          ),
          // Centramos las acciones dentro del diálogo
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                editarTarea(
                  tarea['id'],
                  controllerTitulo.text.trim(),
                  controllerDesc.text.trim(),
                );
                Navigator.pop(context);
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  String obtenerFechaActual() {
    final ahora = DateTime.now();
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

    return '${dias[ahora.weekday - 1]} ${ahora.day} de ${meses[ahora.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Tareas de Hoy',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1F2937),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: cerrarSesion,
            tooltip: 'Cerrar Sesión',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              obtenerFechaActual(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          Expanded(
            child: cargando
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : tareasHoy.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay tareas pendientes',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: tareasHoy.length,
                        itemBuilder: (context, index) {
                          final tarea = tareasHoy[index];
                          final int tareaId = tarea['id'];
                          final String titulo = tarea['titulo'] ?? 'Sin título';
                          final String descripcion = tarea['descripcion'] ?? '';

                          return Dismissible(
                            key: Key('tarea_$tareaId'),
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerLeft,
                              child: const Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Eliminar',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            secondaryBackground: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD8F3DC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Completar',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                await completarTarea(tareaId);
                                return true;
                              } else if (direction == DismissDirection.startToEnd) {
                                await eliminarTarea(tareaId);
                                return true;
                              }
                              return false;
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: IconButton(
                                  icon: Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: colorScheme.secondary,
                                    size: 26,
                                  ),
                                  tooltip: 'Completar Tarea',
                                  onPressed: () => completarTarea(tareaId),
                                ),
                                title: Text(
                                  titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                subtitle: descripcion.isNotEmpty
                                    ? Text(
                                        descripcion,
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 13,
                                        ),
                                      )
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Color(0xFF3B82F6),
                                        size: 20,
                                      ),
                                      onPressed: () => mostrarDialogoEditarTarea(tarea),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 20,
                                      ),
                                      onPressed: () => eliminarTarea(tareaId),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0xFFD8F3DC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Text(
              'Tareas completadas: $totalCompletadasAcumuladas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0, right: 16.0),
        child: FloatingActionButton(
          onPressed: mostrarDialogoNuevaTarea,
          backgroundColor: colorScheme.primary,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}