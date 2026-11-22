package jidoraku.lelexue.dataplatform;

import java.time.Instant;

public record OutboxRecord(
        MasteryChangedEvent event,
        Status status,
        int attempts,
        Instant createdAt,
        Instant updatedAt,
        String lastError) {

    public enum Status { PENDING, SENT, DEAD }

    public OutboxRecord withStatus(Status s, int newAttempts, Instant at, String error) {
        return new OutboxRecord(event, s, newAttempts, createdAt, at, error);
    }
}
