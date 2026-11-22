package jidoraku.lelexue.dataplatform;

import static org.junit.jupiter.api.Assertions.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

class MasteryEvaluatorTest {

    private static final Instant T0 = Instant.parse("2026-11-22T10:00:00Z");

    private static MasteryRule rule(String itemType, String threshold, int minCount, WindowKind w) {
        return new MasteryRule("math", 1, itemType, new BigDecimal(threshold), minCount, w);
    }

    private static List<AnswerAttempt> seq(String itemType, boolean... correct) {
        List<AnswerAttempt> out = new ArrayList<>();
        for (int i = 0; i < correct.length; i++) {
            out.add(new AnswerAttempt("a" + i, correct[i], itemType, T0.plusSeconds(i)));
        }
        return out;
    }

    @Test
    void thresholdIsInclusive() {
        // 4/5 = 0.8 ≥ 0.8 满足；3/5 不满足
        assertTrue(MasteryEvaluator.satisfied(rule(null, "0.8", 5, WindowKind.ALL),
                seq(null, true, true, true, true, false)));
        assertFalse(MasteryEvaluator.satisfied(rule(null, "0.8", 5, WindowKind.ALL),
                seq(null, true, true, true, false, false)));
    }

    @Test
    void notEnoughAttemptsIsNotSatisfied() {
        assertFalse(MasteryEvaluator.satisfied(rule(null, "0.8", 5, WindowKind.ALL),
                seq(null, true, true, true, true)));
    }

    @Test
    void itemTypeFilterIgnoresOtherTypes() {
        List<AnswerAttempt> mixed = new ArrayList<>(seq("apply", true, true, true, true, true));
        mixed.addAll(seq("recognize", false, false, false, false, false));
        assertTrue(MasteryEvaluator.satisfied(rule("apply", "0.8", 5, WindowKind.ALL), mixed));
        assertFalse(MasteryEvaluator.satisfied(rule("recognize", "0.8", 5, WindowKind.ALL), mixed));
    }

    @Test
    void attemptWindowUsesLatestMinCountOnly() {
        // 前 5 题全错，后 5 题全对：滚动窗口（最近 5 题）满足，全部作答 50% 不满足
        List<AnswerAttempt> h = seq(null, false, false, false, false, false, true, true, true, true, true);
        assertTrue(MasteryEvaluator.satisfied(rule(null, "0.8", 5, WindowKind.ATTEMPT), h));
        assertFalse(MasteryEvaluator.satisfied(rule(null, "0.8", 5, WindowKind.ALL), h));
    }
}
