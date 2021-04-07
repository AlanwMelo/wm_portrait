import 'dart:io'
    show RawDatagramSocket, RawSocketEvent, InternetAddress, Datagram;
import 'dart:convert' show utf8;

class NetworkDevices {
  udpServer() => RawDatagramSocket.bind(InternetAddress.anyIPv4, 8000)
          .then((datagramSocket) {
        datagramSocket.readEventsEnabled = true;
        datagramSocket.listen((RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            Datagram dg = datagramSocket.receive();
            if (dg != null) {
              datagramSocket.send(dg.data, dg.address, dg.port);
              print('server');
              print('${dg.address}:${dg.port} -- ${utf8.decode(dg.data)}');
            }
          }
        });
      });

  udpClient() => RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((datagramSocket) {
    datagramSocket.broadcastEnabled = true;
    datagramSocket.readEventsEnabled = true;
    datagramSocket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram dg = datagramSocket.receive();
        if (dg != null) {
          print('client');
          print('${dg.address}:${dg.port} -- ${utf8.decode(dg.data)}');
          //datagramSocket.close();
        }
      }
    });
    datagramSocket.send("io.github.itzmeanjan.transferZ".codeUnits,
        InternetAddress("255.255.255.255"), 8000);
  });
}
