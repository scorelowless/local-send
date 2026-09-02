import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Public interface for network manager functionality used across the app.
///
/// This is the new interface the DI container will register and consumers
/// should depend on. `NetworkManager` implements this interface.
abstract class NetworkManager {
  Stream<Uint8List> get receiveStream;
  String get localId;
  late String localName;

  void addPeer(PeerInfo peer);
  PeerInfo? getPeer(String deviceId);
  PeerInfo? removePeer(String deviceId);

  Future<void> init({int tcpPort, int discoveryPort});
  Future<List<PeerInfo>> discoverDevices({int discoveryPort, Duration timeout});
  Future<String> sendBytes(Uint8List bytes, Map<String, String> metadata);
  Future<void> dispose();
}

/// NetworkManager is a platform-agnostic manager of known peers and
/// higher-level network operations such as sending bytes to a peer.
class NetworkManagerImpl implements NetworkManager {
  /// localId and localName are used to respond to discovery probes.
  NetworkManagerImpl({String? localId, String? localName})
    : localId = localId ?? Platform.localHostname,
      localName = localName ?? Platform.localHostname;

  // deviceId -> PeerInfo
  final Map<String, PeerInfo> peers = {};

  final Random _random = Random();

  final StreamController<Uint8List> _receiveController = StreamController<Uint8List>.broadcast();

  bool _initialized = false;

  static const int defaultDiscoveryPort = 45000;
  static const int defaultTransferPort = 46000;

  RawDatagramSocket? _udpResponder;
  ServerSocket? _tcpServer;

  @override
  String localId;
  @override
  String localName;

  @override
  Stream<Uint8List> get receiveStream => _receiveController.stream;

  @override
  void addPeer(PeerInfo peer) {
    peers[peer.id] = peer;
  }

  @override
  PeerInfo? getPeer(String deviceId) => peers[deviceId];

  @override
  PeerInfo? removePeer(String deviceId) => peers.remove(deviceId);

  /// Initialize network server bindings (TCP server and UDP discovery
  /// responder). This will start a TCP server bound to [tcpPort] and a UDP
  /// responder bound on [discoveryPort] which replies to DISCOVER messages
  /// with a JSON payload describing this node. Calling multiple times is a no-op.
  @override
  Future<void> init({
    int tcpPort = defaultTransferPort,
    int discoveryPort = defaultDiscoveryPort,
  }) async {
    if (_initialized) {
      return;
    }
    // Ensure a persistent UUID is used as localId (fallback to Platform.localHostname if prefs unavailable).
    try {
      await _ensurePersistentUuid();
    } catch (_) {}
    if (kDebugMode) {
      print('NetworkManager: using localId=$localId localName=$localName');
    }

    await Future.wait([_startTcpServer(tcpPort), _startUdpResponder(discoveryPort)]);
    _initialized = true;
  }

  Future<void> _startTcpServer(int tcpPort) async {
    try {
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort);
      _tcpServer!.listen((client) {
        final List<int> buffer = [];
        try {
          client.listen(
            buffer.addAll,
            onDone: () async {
              final bytes = Uint8List.fromList(buffer);
              // Emit received bytes
              _receiveController.add(bytes);
              // Reply with a simple transfer id
              final transferId = 'transfer-${DateTime.now().millisecondsSinceEpoch}';
              try {
                client.add(utf8.encode(transferId));
                await client.flush();
              } catch (_) {}
              try {
                await client.close();
              } catch (_) {}
            },
            onError: (_) {
              if (buffer.isNotEmpty) {
                _receiveController.add(Uint8List.fromList(buffer));
              }
              try {
                client.destroy();
              } catch (_) {}
            },
            cancelOnError: false,
          );
        } catch (err) {
          try {
            client.destroy();
          } catch (_) {}
        }
      });
    } catch (err) {
      // Swallow bind errors; callers may retry or run without server
    }
  }

  Future<void> _startUdpResponder(int discoveryPort) async {
    try {
      final String? localIp = await _chooseLocalIp();
      if (localIp == null) {
        // No network connectivity; skip binding
        return;
      }
      _udpResponder = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
      _udpResponder?.broadcastEnabled = true;
      _udpResponder?.listen((event) {
        if (event == RawSocketEvent.read) {
          final Datagram? datagram = _udpResponder?.receive();
          if (datagram == null || _tcpServer == null) {
            return;
          }
          try {
            final String msg = utf8.decode(datagram.data, allowMalformed: true);
            if (msg == 'DISCOVER') {
              final String resp = jsonEncode({
                'id': localId,
                'ip': localIp,
                'port': _tcpServer!.port,
                'name': localName,
              });
              try {
                _udpResponder?.send(utf8.encode(resp), datagram.address, datagram.port);
              } catch (_) {}
            }
          } catch (_) {}
        }
      });
    } catch (err) {
      // ignore binding errors
    }
  }

  // Choose a local IPv4 address to advertise in discovery responses.
  Future<String?> _chooseLocalIp() async {
    final List<NetworkInterface> interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );

    for (final iface in interfaces) {
      for (final InternetAddress addr in iface.addresses) {
        if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
          return addr.address;
        }
      }
    }
    return null; // not connected / no IPv4
  }

  /// Discover peers by broadcasting a UDP discovery packet and collecting
  /// responses. Returns a list of [PeerInfo].
  @override
  Future<List<PeerInfo>> discoverDevices({
    int discoveryPort = defaultDiscoveryPort,
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    final List<PeerInfo> found = [];
    try {
      final RawDatagramSocket socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      // TODO: why bind udp twice? think about which messages gets sent by which protocol
      socket.broadcastEnabled = true;

      try {
        socket.send(utf8.encode('DISCOVER'), InternetAddress('255.255.255.255'), discoveryPort);
      } catch (_) {}

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final Datagram? datagram = socket.receive();
          if (datagram == null) {
            return;
          }
          try {
            final map = jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
            final String id = map['id'] as String? ?? '';
            // if (id == localId) {
            //   return;
            // }
            // TODO: ignore ourselves
            final String name = map['name'] as String? ?? '';
            final String ip = map['ip'] as String? ?? datagram.address.address;
            final int port = map['port'] as int? ?? 0;
            final p = PeerInfo(id: id, name: name, ip: ip, tcpPort: port);
            found.add(p);
            addPeer(p);
          } catch (_) {}
        }
      });

      await Future<void>.delayed(timeout);
      socket.close();
    } catch (err) {
      // ignore discovery errors
    }
    return found;
  }

  /// Sends raw [bytes] to a peer identified by `senderId` over TCP.
  /// Optionally include [metadata].
  ///
  /// Returns a transfer id string that can be used to correlate the transfer.
  @override
  Future<String> sendBytes(Uint8List bytes, Map<String, String> metadata) async {
    final String targetId = metadata['receiverId'] ?? '';
    final PeerInfo? peer = peers[targetId];
    if (peer == null) {
      throw ArgumentError('Unknown deviceId: $targetId');
    }

    // Resolve peer.ip to a concrete IPv4 address where possible. Discovery
    // responses may advertise a hostname or an address that resolves to
    // a loopback or otherwise-unroutable address; prefer resolving to an
    // explicit IPv4 address and fall back to the advertised value.
    String hostToConnect = peer.ip;
    try {
      final InternetAddress? parsed = InternetAddress.tryParse(peer.ip);
      if (parsed == null) {
        // peer.ip might be a hostname; try DNS lookup.
        final List<InternetAddress> resolved = await InternetAddress.lookup(peer.ip);
        if (resolved.isNotEmpty) {
          // Pick a non-loopback IPv4 address if available.
          final InternetAddress v4 = resolved.firstWhere(
            (a) => a.type == InternetAddressType.IPv4 && !a.isLoopback,
            orElse: () => resolved.first,
          );
          hostToConnect = v4.address;
        }
      } else {
        // If parsed is loopback, still try resolving via datagram if possible.
        if (parsed.isLoopback) {
          // leave hostToConnect as-is; discovery listener should prefer datagram src if needed
        } else {
          hostToConnect = parsed.address;
        }
      }
    } catch (_) {}

    if (kDebugMode) {
      print(
        'NetworkManager: connecting to $hostToConnect:${peer.tcpPort} for deviceId=$targetId (advertised ip=${peer.ip})',
      );
    }

    final Socket socket = await Socket.connect(
      hostToConnect,
      peer.tcpPort,
      timeout: const Duration(seconds: 10),
    );

    try {
      // Simple framing: [4 byte big-endian metadata length][metadata JSON][raw bytes]
      final String metaJson = jsonEncode(metadata);
      final Uint8List metaBytes = utf8.encode(metaJson);
      final header = ByteData(4)..setUint32(0, metaBytes.length);

      socket.add(header.buffer.asUint8List());
      if (metaBytes.isNotEmpty) {
        socket.add(metaBytes);
      }
      socket.add(bytes);

      await socket.flush();

      final String transferId = _generateTransferId();

      // Close the socket after sending. For long-lived connections a
      // different method (reusing sockets) should be added.
      await socket.close();

      return transferId;
    } catch (err) {
      await socket.close();
      rethrow;
    }
  }

  String _generateTransferId() {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int r = _random.nextInt(1 << 32);
    return '$now-$r';
  }

  @override
  Future<void> dispose() async {
    try {
      await _receiveController.close();
    } catch (_) {}
    try {
      _udpResponder?.close();
    } catch (_) {}
    try {
      await _tcpServer?.close();
    } catch (_) {}
  }

  /// Ensure a persistent UUID is available and stored in SharedPreferences.
  /// If a saved UUID exists, use it; otherwise generate a new v4 UUID and persist it.
  Future<void> _ensurePersistentUuid() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      const key = 'device_uuid';
      final String? stored = prefs.getString(key);
      if (stored == null || stored.isEmpty) {
        final String id = const Uuid().v4();
        await prefs.setString(key, id);
        localId = id;
        if (kDebugMode) {
          print('NetworkManager: generated new UUID localId=$localId');
        }
      } else {
        localId = stored;
        if (kDebugMode) {
          print('NetworkManager: loaded persistent UUID localId=$localId');
        }
      }
    } catch (err) {
      // If shared preferences are not available for some reason, keep existing localId
      if (kDebugMode) {
        print('NetworkManager: failed to get persistent uuid: $e');
      }
    }
  }
}

/// Information about a remote peer (device). Stored by [NetworkManagerImpl].
class PeerInfo {
  PeerInfo({
    required this.id,
    required this.name,
    required this.ip,
    required this.tcpPort,
    this.udpPort,
  });

  final String id; // base id (before @)
  final String name;
  final String ip;
  final int tcpPort;
  final int? udpPort;
}
