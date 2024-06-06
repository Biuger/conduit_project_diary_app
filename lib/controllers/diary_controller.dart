import 'package:conduit/conduit.dart';
import 'package:proyecto_conduit/models/diary_entry.dart';
import 'package:proyecto_conduit/proyecto_conduit.dart';

class DiaryController extends ResourceController {
  ManagedContext context;

  DiaryController(this.context);

  @Operation.get()
  Future<Response> getAllEntries() async {
    final query = Query<DiaryEntry>(context);
    final entries = await query.fetch();
    return Response.ok(entries);
  }

  @Operation.get('id')
  Future<Response> getEntryByID(@Bind.path('id') int id) async {
    final query = Query<DiaryEntry>(context)..where((e) => e.id).equalTo(id);
    final entry = await query.fetchOne();
    if (entry == null) {
      return Response.notFound();
    }
    return Response.ok(entry);
  }

  @Operation.post()
  Future<Response> createEntry(@Bind.body() DiaryEntry entry) async {
    final query = Query<DiaryEntry>(context)..values = entry;
    final insertedEntry = await query.insert();
    return Response.ok(insertedEntry);
  }

  @Operation.put('id')
  Future<Response> updateEntry(@Bind.path('id') int id, @Bind.body() DiaryEntry entry) async {
    final query = Query<DiaryEntry>(context)
      ..where((e) => e.id).equalTo(id)
      ..values = entry;
    final updatedEntry = await query.updateOne();
    if (updatedEntry == null) {
      return Response.notFound();
    }
    return Response.ok(updatedEntry);
  }

  @Operation.delete('id')
  Future<Response> deleteEntry(@Bind.path('id') int id) async {
    final query = Query<DiaryEntry>(context)..where((e) => e.id).equalTo(id);
    final deletedEntry = await query.delete();
    if (deletedEntry == 0) {
      return Response.notFound();
    }
    return Response.ok(deletedEntry);
  }
}
