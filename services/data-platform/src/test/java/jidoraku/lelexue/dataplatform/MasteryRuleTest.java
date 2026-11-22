package jidoraku.lelexue.dataplatform;

import static org.junit.jupiter.api.Assertions.*;

import java.math.BigDecimal;
import org.junit.jupiter.api.Test;

class MasteryRuleTest {

    @Test
    void level3IsNotExecutedInThisSlice() {
        assertThrows(IllegalArgumentException.class,
                () -> new MasteryRule("math", 3, null, new BigDecimal("0.8"), 5, WindowKind.ALL));
    }

    @Test
    void thresholdMustBeBetweenZeroAndOne() {
        assertThrows(IllegalArgumentException.class,
                () -> new MasteryRule("math", 1, null, new BigDecimal("1.5"), 5, WindowKind.ALL));
        assertThrows(IllegalArgumentException.class,
                () -> new MasteryRule("math", 1, null, new BigDecimal("-0.1"), 5, WindowKind.ALL));
    }

    @Test
    void minCountMustBePositive() {
        assertThrows(IllegalArgumentException.class,
                () -> new MasteryRule("math", 1, null, new BigDecimal("0.8"), 0, WindowKind.ALL));
    }
}
