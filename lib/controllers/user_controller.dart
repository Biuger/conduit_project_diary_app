import 'package:conduit/conduit.dart';
import 'package:proyecto_conduit/models/user_model.dart' as model;
import 'package:proyecto_conduit/proyecto_conduit.dart';

class UserController extends ResourceController {
  ManagedContext context;

  UserController(this.context);

  @Operation.get()
  Future<Response> getAllUsers() async {
    final query = Query<model.UserModel>(context);
    final users = await query.fetch();
    return Response.ok(users);
  }

  @Operation.post()
  Future<Response> createUser(@Bind.body() model.UserModel user) async {
    final query = Query<model.UserModel>(context)..values = user;
    final insertedUser = await query.insert();
    return Response.ok(insertedUser);
  }

  @Operation.get('email', 'password')
  Future<Response> getByEmailAndPassword(@Bind.query('email') String email, @Bind.query('password') String password) async {
    final query = Query<model.UserModel>(context)
      ..where((u) => u.email).equalTo(email)
      ..where((u) => u.password).equalTo(password);
    final user = await query.fetchOne();
    if (user == null) {
      return Response.unauthorized(body: {"error": "Correo o contraseña incorrectos"});
    }
    return Response.ok(user);
  }
}
