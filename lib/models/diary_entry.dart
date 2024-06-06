import 'package:conduit/conduit.dart';
import 'package:proyecto_conduit/proyecto_conduit.dart';

class DiaryEntry extends ManagedObject<_DiaryEntry> implements _DiaryEntry {}

class _DiaryEntry {
  @primaryKey
  int? id;

  @Column()
  int? id_user;

  @Column(unique: true, indexed: true)
  String? title;

  @Column()
  String? content;

  @Column()
  String? mood;

  @Column(databaseType: ManagedPropertyType.datetime)
  DateTime? dateWithoutTime;

  set date(DateTime? value) {
    if (value != null) {
      dateWithoutTime = DateTime(value.year, value.month, value.day);
    } else {
      dateWithoutTime = null;
    }
  }

  DateTime? get date {
    return dateWithoutTime;
  }
}