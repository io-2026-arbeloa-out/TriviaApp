import 'package:cloud_functions/cloud_functions.dart';

class FirebaseGameCommands {
  final FirebaseFunctions? _functions;

  FirebaseGameCommands({FirebaseFunctions? functions}) : _functions = functions;

  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) async {
    try {
      final functions = _functions ?? FirebaseFunctions.instanceFor(region: 'europe-central2');
      final result = await functions.httpsCallable(name).call(data);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      if (['failed-precondition', 'aborted', 'not-found', 'already-exists'].contains(e.code)) {
        throw StateError(e.message ?? e.code);
      }
      rethrow;
    }
  }
}
