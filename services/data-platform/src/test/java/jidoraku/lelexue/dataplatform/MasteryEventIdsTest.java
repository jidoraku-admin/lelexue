package jidoraku.lelexue.dataplatform;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class MasteryEventIdsTest {

    @Test
    void formatMatchesDecision() {
        assertEquals("math:u1:math.g3.v1.u01.k001:2",
                MasteryEventIds.of("math", "u1", new KnowledgePointId("math.g3.v1.u01.k001"), 2));
    }

    @Test
    void sameBusinessKeyGivesSameId() {
        KnowledgePointId kp = new KnowledgePointId("english.g3.v1.u01.k002");
        assertEquals(MasteryEventIds.of("english", "u9", kp, 1), MasteryEventIds.of("english", "u9", kp, 1));
    }

    @Test
    void overlongIdIsRejected() {
        String longUser = "u".repeat(120);
        assertThrows(IllegalArgumentException.class,
                () -> MasteryEventIds.of("math", longUser, new KnowledgePointId("math.g3.v1.u01.k001"), 1));
    }
}
