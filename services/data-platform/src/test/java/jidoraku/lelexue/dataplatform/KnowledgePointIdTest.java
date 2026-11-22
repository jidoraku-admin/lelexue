package jidoraku.lelexue.dataplatform;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;

class KnowledgePointIdTest {

    @Test
    void acceptsContractFormat() {
        KnowledgePointId id = new KnowledgePointId("math.g3.v1.u01.k001");
        assertEquals("math", id.subject());
    }

    @Test
    void rejectsUppercaseAndWrongShape() {
        assertThrows(IllegalArgumentException.class, () -> new KnowledgePointId("Math.g3.v1.u01.k001"));
        assertThrows(IllegalArgumentException.class, () -> new KnowledgePointId("math.g3.v1.u1.k001"));
        assertThrows(IllegalArgumentException.class, () -> new KnowledgePointId("math.g3.v3.u01.k001"));
    }

    @Test
    void rejectsGradeOutOfRangeAndZeroIndices() {
        assertThrows(IllegalArgumentException.class, () -> new KnowledgePointId("math.g13.v1.u01.k001"));
        assertThrows(IllegalArgumentException.class, () -> new KnowledgePointId("math.g3.v1.u00.k001"));
        assertThrows(IllegalArgumentException.class, () -> new KnowledgePointId("math.g3.v1.u01.k000"));
    }
}
