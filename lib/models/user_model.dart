import 'package:conduit/conduit.dart';
import 'package:proyecto_conduit/proyecto_conduit.dart';

class UserModel extends ManagedObject<_UserModel> implements _UserModel {}

class _UserModel {
  @primaryKey
  int? id;

  @Column(unique: true, indexed: true)
  String? username;

  @Column(unique: true, indexed: true)
  String? email;

  @Column()
  String? password;
}