package jidoraku.lelexue.dataplatform;

import java.math.BigDecimal;
import java.util.Objects;

/**
 * 掌握等级判定规则（gamification §9，共通 v1 格式）。数值由学科提供，不在共通代码中写死。
 * 本切片只执行 1★、2★；3★ 的间隔复习条件待共通增加 metric 后再实现。
 */
public record MasteryRule(
        String subject,
        int level,
        String itemType,
        BigDecimal threshold,
        int minCount,
        WindowKind window) {

    public MasteryRule {
        Objects.requireNonNull(subject, "subject");
        Objects.requireNonNull(threshold, "threshold");
        Objects.requireNonNull(window, "window");
        if (level != 1 && level != 2) {
            throw new IllegalArgumentException("本切片只执行 1★、2★ 的规则: " + level);
        }
        if (threshold.signum() < 0 || threshold.compareTo(BigDecimal.ONE) > 0) {
            throw new IllegalArgumentException("threshold 必须在 0–1 之间: " + threshold);
        }
        if (minCount < 1) {
            throw new IllegalArgumentException("minCount 必须大于 0: " + minCount);
        }
    }
}
