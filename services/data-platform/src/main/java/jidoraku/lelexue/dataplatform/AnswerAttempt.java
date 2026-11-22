package jidoraku.lelexue.dataplatform;

import java.time.Instant;

/**
 * 一次作答记录（判定所需的最小字段）。
 * attemptId 是作答的幂等键：同一次提交重试时必须使用同一个 attemptId（#112 审核要求）。
 */
public record AnswerAttempt(String attemptId, boolean correct, String itemType, Instant answeredAt) {
}
