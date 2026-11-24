package jidoraku.lelexue.dataplatform;

import java.math.BigDecimal;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

/** 纯函数判定：给定规则与按时间升序的作答历史，判断是否满足规则。 */
public final class MasteryEvaluator {

    private MasteryEvaluator() {
    }

    public static boolean satisfied(MasteryRule rule, List<AnswerAttempt> chronological) {
        Objects.requireNonNull(rule, "rule");
        List<AnswerAttempt> filtered = chronological.stream()
                .filter(a -> rule.itemType() == null || rule.itemType().equals(a.itemType()))
                .collect(Collectors.toList());

        List<AnswerAttempt> window;
        if (rule.window() == WindowKind.ATTEMPT) {
            if (filtered.size() < rule.minCount()) {
                return false;
            }
            window = filtered.subList(filtered.size() - rule.minCount(), filtered.size());
        } else {
            window = filtered;
        }
        int n = window.size();
        if (n < rule.minCount()) {
            return false;
        }
        long correct = window.stream().filter(AnswerAttempt::correct).count();
        // 用 BigDecimal 比较，避免浮点误差：correct / n >= threshold
        return BigDecimal.valueOf(correct).compareTo(rule.threshold().multiply(BigDecimal.valueOf(n))) >= 0;
    }
}
