package jidoraku.lelexue.dataplatform;

import static org.junit.jupiter.api.Assertions.*;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import javax.sql.DataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class JdbcConsumerDedupeTest {

    private static final Instant T0 = Instant.parse("2026-11-22T10:00:00Z");
    private static final Clock CLOCK = Clock.fixed(T0, ZoneOffset.UTC);
    private DataSource ds;

    @BeforeEach
    void setUp() {
        ds = MysqlTestDatabase.reset();
    }

    private static MasteryChangedEvent ev(String eventId, String user, int level) {
        return new MasteryChangedEvent(eventId, user, "math", new KnowledgePointId("math.g3.v1.u01.k001"), level, T0);
    }

    @Test
    void redeliveredEventIsIgnored() {
        JdbcConsumerDedupe d = new JdbcConsumerDedupe(ds, CLOCK);
        assertTrue(d.accept(ev("e1", "u1", 1)));
        assertFalse(d.accept(ev("e1", "u1", 1)));
    }

    @Test
    void sameBusinessKeyWithNewEventIdGrantsOnlyOnce() {
        JdbcConsumerDedupe d = new JdbcConsumerDedupe(ds, CLOCK);
        assertTrue(d.accept(ev("e1", "u1", 1)));
        assertFalse(d.accept(ev("e2", "u1", 1)));
    }

    @Test
    void differentLevelGrantsAgain() {
        JdbcConsumerDedupe d = new JdbcConsumerDedupe(ds, CLOCK);
        assertTrue(d.accept(ev("e1", "u1", 1)));
        assertTrue(d.accept(ev("e2", "u1", 2)));
    }

    @Test
    void dedupeSurvivesRestart() {
        assertTrue(new JdbcConsumerDedupe(ds, CLOCK).accept(ev("e1", "u1", 1)));
        JdbcConsumerDedupe afterRestart = new JdbcConsumerDedupe(ds, CLOCK);
        assertFalse(afterRestart.accept(ev("e1", "u1", 1)), "重启后同一 eventId 不得再次处理");
        assertFalse(afterRestart.accept(ev("e9", "u1", 1)), "重启后同一业务键不得再次发放");
    }
}
