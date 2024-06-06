import 'package:proyecto_conduit/proyecto_conduit.dart';
import 'package:conduit_test/conduit_test.dart';

export 'package:proyecto_conduit/proyecto_conduit.dart';
export 'package:conduit_test/conduit_test.dart';
export 'package:test/test.dart';
/// A testing harness for proyecto_conduit.
///
/// A harness for testing an conduit application. Example test file:
///
///         void main() {
///           Harness harness = Harness()..install();
///
///           test("GET /path returns 200", () async {
///             final response = await harness.agent.get("/path");
///             expectResponse(response, 200);
///           });
///         }
///
class Harness extends TestHarness<MyChannel> {
  @override
  Future onSetUp() async {}

  @override
  Future onTearDown() async {}
}
