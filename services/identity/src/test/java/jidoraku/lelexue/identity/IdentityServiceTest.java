package jidoraku.lelexue.identity;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import org.springframework.jdbc.datasource.DriverManagerDataSource;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class IdentityServiceTest {

    private IdentityService svc;

    @BeforeEach
    void setUp() {
        DriverManagerDataSource ds = new DriverManagerDataSource(
                System.getenv().getOrDefault("IDENTITY_TEST_DB_URL",
                        "jdbc:mysql://localhost:3306/identity_test?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"),
                System.getenv().getOrDefault("IDENTITY_TEST_DB_USER", "identity_test"),
                System.getenv().getOrDefault("IDENTITY_TEST_DB_PASSWORD", "identity_test"));
        Flyway flyway = Flyway.configure().dataSource(ds).locations("classpath:db/migration").cleanDisabled(false).load();
        flyway.clean();
        flyway.migrate();
        svc = new IdentityService(ds, 3);
        svc.registerParent("p1", null);
    }

    @Test
    void parentCanCreateUpToThreeStudents() {
        for (int i = 1; i <= 3; i++) {
            svc.createStudent("p1", "s" + i, "stu" + i);
        }
        assertEquals(3, svc.seatsUsed("p1"));
        assertThrows(IdentityException.class, () -> svc.createStudent("p1", "s4", "stu4"));
    }

    @Test
    void failedCreateLeavesNoAccountBehind() {
        for (int i = 1; i <= 3; i++) {
            svc.createStudent("p1", "s" + i, "stu" + i);
        }
        assertThrows(IdentityException.class, () -> svc.createStudent("p1", "s4", "stu4"));
        // 失败后同一登录名不应被占用
        svc.unlink("p1", "s1");
        svc.createStudent("p1", "s4", "stu4");
        assertEquals(3, svc.seatsUsed("p1"));
    }

    @Test
    void unlinkFreesSeat() {
        svc.createStudent("p1", "s1", "stu1");
        svc.unlink("p1", "s1");
        assertEquals(0, svc.seatsUsed("p1"));
    }

    @Test
    void loginNameRules() {
        for (String bad : new String[]{"abc", "Abcd", "ab cd", "abc-d", "a".repeat(17)}) {
            assertThrows(IdentityException.class, () -> svc.createStudent("p1", "x", bad), bad);
        }
    }

    @Test
    void loginNameIsUnique() {
        svc.createStudent("p1", "s1", "same1");
        assertThrows(IdentityException.class, () -> svc.createStudent("p1", "s2", "same1"));
    }

    @Test
    void studentsInheritEntitlement() {
        svc.setEntitlement("p1", new Entitlement(true, false));
        svc.createStudent("p1", "s1", "stu1");
        assertTrue(svc.getEntitlement("s1").active());
    }

    @Test
    void studentCannotCreateStudent() {
        svc.createStudent("p1", "s1", "stu1");
        assertThrows(IdentityException.class, () -> svc.createStudent("s1", "s2", "stu2"));
    }

    @Test
    void classAccountUsesSeatLimit() {
        svc.registerParent("c1", 1);
        svc.createStudent("c1", "s1", "stu1");
        assertThrows(IdentityException.class, () -> svc.createStudent("c1", "s2", "stu2"));
    }

    @Test
    void unknownParentIsRejected() {
        assertThrows(IdentityException.class, () -> svc.createStudent("nobody", "s1", "stu1"));
        assertFalse(svc.getEntitlement("nobody").active());
    }
}
