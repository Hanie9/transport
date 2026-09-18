import 'package:flutter_test/flutter_test.dart';
import 'package:legestic/models/user.dart';

void main() {
  test('cargo acceptance requires plate, model and trailer type', () {
    VehicleInfo vehicle(String plate, String model, String type) =>
        VehicleInfo(plateNumber: plate, vehicleModel: model, cargoType: type);
    expect(vehicle('', '', '').isCompleteForCargoAcceptance, isFalse);
    expect(vehicle('  ', 'ولوو', 'کفی').isCompleteForCargoAcceptance, isFalse);
    expect(
      vehicle('۱۲ ب ۳۴۵ ایران ۶۶', '', 'کفی').isCompleteForCargoAcceptance,
      isFalse,
    );
    expect(
      vehicle('۱۲ ب ۳۴۵ ایران ۶۶', 'ولوو', '').isCompleteForCargoAcceptance,
      isFalse,
    );
    expect(
      vehicle('۱۲ ب ۳۴۵ ایران ۶۶', 'ولوو', 'کفی').isCompleteForCargoAcceptance,
      isTrue,
    );
  });
}
