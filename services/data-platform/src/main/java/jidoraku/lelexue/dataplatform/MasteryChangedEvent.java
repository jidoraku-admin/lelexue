package jidoraku.lelexue.dataplatform;

import java.time.Instant;
import java.util.List;
import java.util.Objects;

/**
 * MasteryChanged v1 事件（字段以 packages/shared/lib/core/mastery_changed.dart 为准）。
 * eventId 为消费方去重键；(userId, subject, knowledgePointId, level) 为经验发放的业务唯一键。
 */
public record MasteryChangedEvent(
        String eventId,
        String userId,
        String subject,
        KnowledgePointId knowledgePointId,
        int level,
        Instant achievedAt) {

    public MasteryChangedEvent {
        requireText(eventId, "eventId");
        requireText(userId, "userId");
        requireText(subject, "subject");
        Objects.requireNonNull(knowledgePointId, "knowledgePointId");
        Objects.requireNonNull(achievedAt, "achievedAt");
        if (level < 1 || level > 3) {
            throw new IllegalArgumentException("level 只能是 1（识别）、2（应用）、3（迁移）: " + level);
        }
        if (!knowledgePointId.subject().equals(subject)) {
            throw new IllegalArgumentException("knowledgePointId 的学科与 subject 不一致");
        }
    }

    /** 经验发放的业务唯一键（gamification §3）。 */
    public List<String> businessKey() {
        return List.of(userId, subject, knowledgePointId.value(), Integer.toString(level));
    }

    private static void requireText(String v, String name) {
        if (v == null || v.isBlank()) {
            throw new IllegalArgumentException(name + " 不能为空");
        }
    }
}
