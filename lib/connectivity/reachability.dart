import 'reachability_stub.dart'
    if (dart.library.io) 'reachability_io.dart' as impl;

Future<bool> verifyInternetReachable() => impl.verifyInternetReachable();
