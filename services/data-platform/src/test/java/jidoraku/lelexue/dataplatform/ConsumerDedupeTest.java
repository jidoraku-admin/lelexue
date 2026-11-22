package jidoraku.lelexue.dataplatform;

import static org.junit.jupiter.api.Assertions.*;

import java.time.Instant;
import org.junit.jupiter.api.Test;

class ConsumerDedupeTest {

    private static MasteryChangedEvent ev(String eventId, String user, int level) {
        return new MasteryChangedEvent(eventId, user, "math", new KnowledgePointId("math.g3.v1.u01.k001"),
                level, Instant.parse("2026-11-22T10:00:00Z"));
    }

    @Test
    void redeliveredEventIsIgnored() {
        ConsumerDedupe d = new ConsumerDedupe();
        assertTrue(d.accept(ev("e1", "u1", 1)));
        assertFalse(d.accept(ev("e1", "u1", 1)));
    }

    @Test
    void sameBusinessKeyWithNewEventIdGrantsOnlyOnce() {
        ConsumerDedupe d = new ConsumerDedupe();
        assertTrue(d.accept(ev("e1", "u1", 1)));
        assertFalse(d.accept(ev("e2", "u1", 1)));
    }

    @Test
    void differentLevelGrantsAgain() {
        ConsumerDedupe d = new ConsumerDedupe();
        assertTrue(d.accept(ev("e1", "u1", 1)));
        assertTrue(d.accept(ev("e2", "u1", 2)));
    }
}
