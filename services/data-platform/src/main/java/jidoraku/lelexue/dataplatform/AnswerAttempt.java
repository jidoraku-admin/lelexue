package jidoraku.lelexue.dataplatform;

import java.time.Instant;

/** 一次作答记录（判定所需的最小字段）。 */
public record AnswerAttempt(boolean correct, String itemType, Instant answeredAt) {
}
