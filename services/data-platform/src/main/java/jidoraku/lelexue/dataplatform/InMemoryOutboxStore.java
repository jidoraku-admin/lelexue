package jidoraku.lelexue.dataplatform;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class InMemoryOutboxStore implements OutboxStore {

    static final Duration SENT_RETENTION = Duration.ofDays(7);
    static final Duration DEAD_RETENTION = Duration.ofDays(30);

    private final Map<String, OutboxRecord> records = new LinkedHashMap<>();

    @Override
    public synchronized void append(MasteryChangedEvent event, Instant now) {
        records.putIfAbsent(event.eventId(),
                new OutboxRecord(event, OutboxRecord.Status.PENDING, 0, now, now, null));
    }

    @Override
    public synchronized List<OutboxRecord> pending(int limit) {
        List<OutboxRecord> out = new ArrayList<>();
        for (OutboxRecord r : records.values()) {
            if (r.status() == OutboxRecord.Status.PENDING) {
                out.add(r);
                if (out.size() >= limit) break;
            }
        }
        return out;
    }

    @Override
    public synchronized void markSent(String eventId, Instant now) {
        OutboxRecord r = records.get(eventId);
        if (r != null) {
            records.put(eventId, r.withStatus(OutboxRecord.Status.SENT, r.attempts() + 1, now, null));
        }
    }

    @Override
    public synchronized void markFailed(String eventId, String reason, int maxAttempts, Instant now) {
        OutboxRecord r = records.get(eventId);
        if (r == null) return;
        int attempts = r.attempts() + 1;
        OutboxRecord.Status next = attempts >= maxAttempts ? OutboxRecord.Status.DEAD : OutboxRecord.Status.PENDING;
        records.put(eventId, r.withStatus(next, attempts, now, reason));
    }

    @Override
    public synchronized void purge(Instant now) {
        records.values().removeIf(r ->
                (r.status() == OutboxRecord.Status.SENT && r.updatedAt().isBefore(now.minus(SENT_RETENTION)))
                        || (r.status() == OutboxRecord.Status.DEAD && r.updatedAt().isBefore(now.minus(DEAD_RETENTION))));
    }

    @Override
    public synchronized List<OutboxRecord> deadLetters() {
        List<OutboxRecord> out = new ArrayList<>();
        for (OutboxRecord r : records.values()) {
            if (r.status() == OutboxRecord.Status.DEAD) out.add(r);
        }
        return out;
    }
}
