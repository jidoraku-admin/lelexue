package jidoraku.lelexue.dataplatform;

import static org.junit.jupiter.api.Assertions.*;

import java.time.Instant;
import javax.sql.DataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class JdbcOutboxStoreTest {

    private static final Instant T0 = Instant.parse("2026-11-22T10:00:00Z");
    private JdbcOutboxStore store;

    @BeforeEach
    void setUp() {
        DataSource ds = MysqlTestDatabase.reset();
        store = new JdbcOutboxStore(ds);
    }

    private static MasteryChangedEvent ev(String id, String user) {
        return new MasteryChangedEvent(id, user, "math", new KnowledgePointId("math.g3.v1.u01.k001"), 1, T0);
    }

    @Test
    void appendWithSameEventIdIsIdempotent() {
        store.append(ev("e1", "u1"), T0);
        store.append(ev("e1", "u1"), T0);
        assertEquals(1, store.pending(10).size());
    }

    @Test
    void roundTripsEventFieldsAndUtcTimestamps() {
        store.append(ev("e1", "u1"), T0);
        OutboxRecord r = store.pending(10).get(0);
        assertEquals(ev("e1", "u1"), r.event());
        assertEquals(T0, r.event().achievedAt());
        assertEquals(OutboxRecord.Status.PENDING, r.status());
    }

    @Test
    void pendingIsOrderedByCreation() {
        store.append(ev("e2", "u1"), T0.plusSeconds(5));
        store.append(ev("e1", "u1"), T0);
        assertEquals("e1", store.pending(10).get(0).event().eventId());
        assertEquals("e2", store.pending(10).get(1).event().eventId());
    }

    @Test
    void markSentRemovesFromPending() {
        store.append(ev("e1", "u1"), T0);
        store.markSent("e1", T0);
        assertTrue(store.pending(10).isEmpty());
    }

    @Test
    void failureStaysPendingUntilLimitThenDead() {
        store.append(ev("e1", "u1"), T0);
        store.markFailed("e1", "bus down", 2, T0);
        assertEquals(OutboxRecord.Status.PENDING, store.pending(10).get(0).status());
        store.markFailed("e1", "bus down again", 2, T0);
        assertTrue(store.pending(10).isEmpty());
        assertEquals(1, store.deadLetters().size());
        assertEquals("bus down again", store.deadLetters().get(0).lastError());
        assertEquals(2, store.deadLetters().get(0).attempts());
    }

    @Test
    void purgeUsesSevenDayAndThirtyDayWindows() {
        store.append(ev("sent", "u1"), T0);
        store.markSent("sent", T0);
        store.append(ev("dead", "u1"), T0);
        store.markFailed("dead", "x", 1, T0);

        store.purge(T0.plusSeconds(8L * 86400));
        assertEquals(1, store.deadLetters().size(), "死信 8 天后仍保留");

        store.purge(T0.plusSeconds(31L * 86400));
        assertTrue(store.deadLetters().isEmpty(), "死信 30 天后清理");
    }
}
