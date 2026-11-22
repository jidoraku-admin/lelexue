import 'package:shared/core/core.dart';
import 'package:shared/identity/identity_service.dart';
import 'package:test/test.dart';

void main() {
  late IdentityService svc;
  late UserId parent;

  setUp(() {
    svc = IdentityService();
    parent = svc.registerParent(UserId('p1'));
  });

  test('parent can create up to 3 students', () {
    for (var i = 1; i <= 3; i++) {
      svc.createStudent(parentId: parent, studentId: UserId('s$i'), loginName: 'stu$i');
    }
    expect(svc.seatsUsed(parent), 3);
    expect(
      () => svc.createStudent(parentId: parent, studentId: UserId('s4'), loginName: 'stu4'),
      throwsA(isA<IdentityException>()),
    );
  });

  test('unlink frees a seat', () {
    svc.createStudent(parentId: parent, studentId: UserId('s1'), loginName: 'stu1');
    svc.unlink(parent, UserId('s1'));
    expect(svc.seatsUsed(parent), 0);
  });

  test('login name must be 4-16 lowercase letters or digits', () {
    for (final bad in ['abc', 'Abcd', 'ab cd', 'a' * 17, 'abc-d']) {
      expect(
        () => svc.createStudent(parentId: parent, studentId: UserId('x'), loginName: bad),
        throwsA(isA<IdentityException>()),
        reason: bad,
      );
    }
  });

  test('login names are unique', () {
    svc.createStudent(parentId: parent, studentId: UserId('s1'), loginName: 'same1');
    expect(
      () => svc.createStudent(parentId: parent, studentId: UserId('s2'), loginName: 'same1'),
      throwsA(isA<IdentityException>()),
    );
  });

  test('students inherit entitlement from parent', () {
    svc.setEntitlement(parent, const Entitlement(paid: true, trialActive: false));
    svc.createStudent(parentId: parent, studentId: UserId('s1'), loginName: 'stu1');
    expect(svc.getEntitlement(UserId('s1')).active, isTrue);
  });

  test('students cannot purchase or create accounts', () {
    svc.createStudent(parentId: parent, studentId: UserId('s1'), loginName: 'stu1');
    expect(() => svc.purchase(UserId('s1')), throwsA(isA<IdentityException>()));
    expect(
      () => svc.createStudent(parentId: UserId('s1'), studentId: UserId('s2'), loginName: 'stu2'),
      throwsA(isA<IdentityException>()),
    );
  });

  test('class account uses configured seat limit', () {
    final cls = svc.registerParent(UserId('c1'), seatLimit: 1);
    svc.createStudent(parentId: cls, studentId: UserId('s1'), loginName: 'stu1');
    expect(
      () => svc.createStudent(parentId: cls, studentId: UserId('s2'), loginName: 'stu2'),
      throwsA(isA<IdentityException>()),
    );
  });
}
