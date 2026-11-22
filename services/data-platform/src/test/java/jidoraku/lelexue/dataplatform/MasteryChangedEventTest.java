package jidoraku.lelexue.dataplatform;

import static org.junit.jupiter.api.Assertions.*;

import java.time.Instant;
import org.junit.jupiter.api.Test;

class MasteryChangedEventTest {

    private static MasteryChangedEvent event(String eventId, String subject, String kp, int level) {
        return new MasteryChangedEvent(eventId, "u1", subject, new KnowledgePointId(kp), level, Instant.parse("2026-11-22T10:00:00Z"));
    }

    @Test
    void businessKeyUsesUserSubjectKnowledgePointLevel() {
        assertEquals(java.util.List.of("u1", "math", "math.g3.v1.u01.k001", "2"),
                event("e1", "math", "math.g3.v1.u01.k001", 2).businessKey());
    }

    @Test
    void rejectsLevelOutsideOneToThree() {
        assertThrows(IllegalArgumentException.class, () -> event("e1", "math", "math.g3.v1.u01.k001", 0));
        assertThrows(IllegalArgumentException.class, () -> event("e1", "math", "math.g3.v1.u01.k001", 4));
    }

    @Test
    void rejectsSubjectMismatchWithKnowledgePoint() {
        assertThrows(IllegalArgumentException.class, () -> event("e1", "english", "math.g3.v1.u01.k001", 1));
    }

    @Test
    void rejectsBlankEventId() {
        assertThrows(IllegalArgumentException.class, () -> event(" ", "math", "math.g3.v1.u01.k001", 1));
    }
}
