import 'package:biteplate_app/domain/restaurant_service.dart';
import 'package:biteplate_app/server/api_server.dart';

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? 8080 : 8080;
  final service = RestaurantService();
  await ApiServer(service, port: port).start();
}
