import 'dart:async';
import 'dart:isolate';

import '../../domain/entities/help_article.dart';
import 'help_search_index.dart';

/// Long-lived isolate that owns a [HelpSearchIndexData] and serves ranked
/// query requests.
///
/// Lifecycle:
/// - [start] spawns the isolate with an initial corpus and waits for the
///   command [SendPort] to come back.
/// - [updateCorpus] kills the current isolate and respawns a new one with the
///   new corpus. The respawn is intentional: it keeps the worker code
///   stateless past the initial build, avoids cross-isolate index mutation,
///   and matches the F-J-3 spec which calls for a respawn whenever the
///   Firestore article stream emits a new corpus.
/// - [search] sends a query envelope across the isolate boundary and awaits a
///   list of ranked article ids. Only the ids cross back; the index itself
///   stays inside the worker.
/// - [dispose] kills the isolate and closes ports.
class HelpSearchIsolate {
  HelpSearchIsolate();

  Isolate? _isolate;
  SendPort? _commandPort;
  ReceivePort? _responsePort;
  StreamSubscription<dynamic>? _responseSubscription;
  bool _running = false;

  bool get isRunning => _running && _commandPort != null;

  Future<void> start(List<HelpArticle> corpus) async {
    await _terminate();

    final responsePort = ReceivePort();
    final readyCompleter = Completer<SendPort>();

    _responsePort = responsePort;
    _responseSubscription = responsePort.listen((message) {
      if (message is SendPort && !readyCompleter.isCompleted) {
        readyCompleter.complete(message);
      }
    });

    _isolate = await Isolate.spawn<_IsolateInit>(
      _helpSearchIsolateEntry,
      _IsolateInit(
        corpus: List<HelpArticle>.unmodifiable(corpus),
        replyPort: responsePort.sendPort,
      ),
      errorsAreFatal: false,
      debugName: 'help-search-isolate',
    );

    _commandPort = await readyCompleter.future;
    _running = true;
  }

  Future<void> updateCorpus(List<HelpArticle> corpus) {
    return start(corpus);
  }

  Future<List<String>> search(String query, {int limit = 20}) async {
    final commandPort = _commandPort;
    if (commandPort == null || !_running) {
      return const <String>[];
    }
    if (limit <= 0) {
      return const <String>[];
    }

    final replyPort = ReceivePort();
    commandPort.send(
      _QueryRequest(
        query: query,
        limit: limit,
        replyPort: replyPort.sendPort,
      ),
    );

    final response = await replyPort.first;
    replyPort.close();

    if (response is List) {
      return response.whereType<String>().toList(growable: false);
    }
    return const <String>[];
  }

  Future<void> dispose() => _terminate();

  Future<void> _terminate() async {
    _running = false;
    _commandPort = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    await _responseSubscription?.cancel();
    _responseSubscription = null;
    _responsePort?.close();
    _responsePort = null;
  }
}

class _IsolateInit {
  const _IsolateInit({required this.corpus, required this.replyPort});

  final List<HelpArticle> corpus;
  final SendPort replyPort;
}

class _QueryRequest {
  const _QueryRequest({
    required this.query,
    required this.limit,
    required this.replyPort,
  });

  final String query;
  final int limit;
  final SendPort replyPort;
}

void _helpSearchIsolateEntry(_IsolateInit init) {
  final commandPort = ReceivePort();
  init.replyPort.send(commandPort.sendPort);

  final index = buildHelpSearchIndex(init.corpus);

  commandPort.listen((message) {
    if (message is _QueryRequest) {
      final results = runHelpSearchQuery(index, message.query, message.limit);
      message.replyPort.send(results);
    }
  });
}
