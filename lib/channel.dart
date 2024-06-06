import 'dart:convert';
import 'package:conduit/conduit.dart';
import 'package:mysql1/mysql1.dart';
import 'dart:io';
import 'package:proyecto_conduit/proyecto_conduit.dart';

class MyChannel extends ApplicationChannel {
  MySqlConnection? connection;

  @override
  Future prepare() async {
    print('Preparando configuración...');
    final configPath = options!.configurationFilePath ?? 'config.yaml';
    print('Usando archivo de configuración: $configPath');

    try {
      final config = MyConfiguration(configPath);
      print('Configuración leída correctamente');

      final dbSettings = ConnectionSettings(
        host: config.database.host,
        port: config.database.port,
        user: config.database.username,
        password: config.database.password,
        db: config.database.databaseName,
      );

      connection = await MySqlConnection.connect(dbSettings);
      print('Conexión a la base de datos establecida');
    } catch (e) {
      print('Error al leer la configuración o conectar a la base de datos: $e');
    }

    logger.onRecord.listen(
        (rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
  }

  @override
  Controller get entryPoint {
    final router = Router();

    // Rutas existentes
    router.route('/diary_entries/[:id]').link(() => MyController(connection!));
    router.route('/users/[:id]').link(() => UserController(connection!));


    // Nueva ruta para la operación GET por correo y contraseña
    router.route('/login').linkFunction((request) async {
      final queryParams = request.raw.uri.queryParameters;
      final email = queryParams['email'];
      final password = queryParams['password'];
      if (email == null || password == null) {
        return Response.badRequest(body: {'error': 'Email and password are required.'});
      }
      final loginController = LoginController(connection!);
      return await loginController.getByEmailAndPassword(email, password);
    });

    return router;
  }
}

class MyConfiguration extends Configuration {
  MyConfiguration(String path) : super.fromFile(File(path));

  late DatabaseConfiguration database;
}

class DatabaseConfiguration extends Configuration {
  late String host;
  late int port;
  late String username;
  late String password;
  late String databaseName;
  late bool isTemporary; // Nueva propiedad

  DatabaseConfiguration();

  @override
  void readFromMap(Map<String, dynamic> map) {
    host = map['host'] as String;
    port = int.parse(map['port'].toString());
    username = map['username'] as String;
    password = map['password'] as String;
    databaseName = map['databaseName'] as String;
    isTemporary =
        map['isTemporary'] as bool; // Asignación de la propiedad isTemporary
  }
}

class MyController extends ResourceController {
  MyController(this.connection);
  final MySqlConnection connection;

  @Operation.get()
Future<Response> getAll(@Bind.query('id_user') int userId) async {
  try {
    final results = await connection.query(
        'SELECT * FROM diary_entries WHERE id_user = ?', [userId]);
    final data = results.map((row) {
      final mappedRow = {};
      row.fields.forEach((key, value) {
        mappedRow[key] = _convertToEncodable(value);
      });
      return mappedRow;
    }).toList();
    return Response.ok(data)..contentType = ContentType.json;
  } catch (e) {
    print("Error al obtener entradas: $e");
    return Response.serverError(body: {'error': e.toString()});
  }
}

  @Operation.post()
  Future<Response> createEntry(@Bind.body() Map<String, dynamic> entry) async {
    try {
      final result = await connection.query(
        'INSERT INTO diary_entries (Id_user, title, content, mood, date) VALUES (?, ?, ?, ?, ?)',
        [entry['Id_user'], entry['title'], entry['content'], entry['mood'], entry['date']],
      );

      final insertedId = result.insertId;
      final insertedEntry = await connection.query(
        'SELECT * FROM diary_entries WHERE id = ?', [insertedId],
      );

  
      final updatedEntries = await connection.query('SELECT * FROM diary_entries');
      final data = updatedEntries.map((row) {
        final mappedRow = {};
        row.fields.forEach((key, value) {
          mappedRow[key] = _convertToEncodable(value);
        });
        return mappedRow;
      }).toList();

      return Response.ok(data)..contentType = ContentType.json;
    } catch (e) {
      print("Error al crear entrada: $e");
      return Response.serverError(body: {'error': e.toString()});
    }
  }

  @Operation.put('id')
  Future<Response> updateEntry(@Bind.path('id') int id, @Bind.body() Map<String, dynamic> entry) async {
    try {
      final result = await connection.query(
        'UPDATE diary_entries SET Id_user = ?, title = ?, content = ?, mood = ?, date = ? WHERE id = ?',
        [entry['Id_user'], entry['title'], entry['content'], entry['mood'], entry['date'], id],
      );

      if (result.affectedRows == 0) {
        return Response.notFound();
      }

      final updatedEntry = await connection.query(
        'SELECT * FROM diary_entries WHERE id = ?', [id],
      );

      if (updatedEntry.isEmpty) {
        return Response.notFound();
      }

      final data = updatedEntry.first.fields.map((key, value) {
        return MapEntry(key, _convertToEncodable(value));
      });

      return Response.ok(data)..contentType = ContentType.json;
    } catch (e) {
      print("Error al actualizar entrada: $e");
      return Response.serverError(body: {'error': e.toString()});
    }
  }

  @Operation.delete('id')
  Future<Response> deleteEntry(@Bind.path('id') int id) async {
    try {
      final result = await connection.query(
        'DELETE FROM diary_entries WHERE id = ?', [id],
      );

      if (result.affectedRows == 0) {
        return Response.notFound();
      }

      
      final updatedEntries = await connection.query('SELECT * FROM diary_entries');
      final data = updatedEntries.map((row) {
        final mappedRow = {};
        row.fields.forEach((key, value) {
          mappedRow[key] = _convertToEncodable(value);
        });
        return mappedRow;
      }).toList();

      return Response.ok(data)..contentType = ContentType.json;
    } catch (e) {
      print("Error al eliminar entrada: $e");
      return Response.serverError(body: {'error': e.toString()});
    }
  }

  dynamic _convertToEncodable(dynamic value) {
    if (value is Blob) {
      return value.toString(); // O usa una codificación diferente si es necesario
    } else if (value is DateTime) {
      return value.toString();
    } else {
      return value;
    }
  }
}

class UserController extends ResourceController {
  final MySqlConnection connection;

  UserController(this.connection);

  @Operation.post()
  Future<Response> createUser(@Bind.body() UserModel user) async {
    final result = await connection.query(
      'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
      [user.username, user.email, user.password],
    );
    final insertedId = result.insertId;
    final insertedUser = await connection.query('SELECT * FROM users WHERE id = ?', [insertedId]);
    return Response.ok(insertedUser.first.fields);
  }
 
}

class LoginController extends ResourceController {
  final MySqlConnection connection;

  LoginController(this.connection);

   @Operation.get('email', 'password')
  Future<Response> getByEmailAndPassword(
      @Bind.query('email') String email,
      @Bind.query('password') String password) async {
    final results = await connection.query(
      'SELECT * FROM users WHERE email = ? AND password = ?',
      [email, password],
    );
    if (results.isEmpty) {
      return Response.unauthorized();
    }
    return Response.ok(results.first.fields);
  }
}

class UserModel extends Serializable {
  String? username;
  String? email;
  String? password;
  

  @override
  Map<String, dynamic> asMap() {
    return {
      'username': username,
      'email': email,
      'password': password,
    };
  }

  @override
  void readFromMap(Map<String, dynamic> object) {
    username = object['username'] as String?;
    email = object['email'] as String?;
    password = object['password'] as String?;
    
  }
}

