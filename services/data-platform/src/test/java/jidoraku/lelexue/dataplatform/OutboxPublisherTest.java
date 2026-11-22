package jidoraku.lelexue.dataplatform;

import static org.junit.jupiter.api.Assertions.*;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

class OutboxPublisherTest {

    private static final Instant T0 = Instant.parse("2026-11-22T10:00:00Z");
    private static final Clock CLOCK = Clock.fixed(T0, ZoneOffset.UTC);

    private static MasteryChangedEvent ev(String id) {
        return new MasteryChangedEvent(id, "u1", "math", new KnowledgePointId("math.g3.v1.u01.k001"), 1, T0);
    }

    @Test
    void deliversPendingEventsAndMarksSent() {
        InMemoryOutboxStore store = new InMemoryOutboxStore();
        store.append(ev("e1"), T0);
        List<MasteryChangedEvent> delivered = new ArrayList<>();
        OutboxPublisher p = new OutboxPublisher(store, delivered::add, 10, 3, CLOCK);

        assertEquals(1, p.pollOnce());
        assertEquals(0, p.pollOnce(), "已发布的事件不会再次投递");
        assertEquals(1, delivered.size());
    }

    @Test
    void failedDeliveryStaysPendingUntilMaxAttemptsThenDead() {
        InMemoryOutboxStore store = new InMemoryOutboxStore();
        store.append(ev("e1"), T0);
        OutboxPublisher p = new OutboxPublisher(store, e -> { throw new IllegalStateException("bus down"); }, 10, 2, CLOCK);

        assertEquals(0, p.pollOnce());
        assertEquals(1, store.pending(10).size(), "第一次失败后仍待发布");
        assertEquals(0, p.pollOnce());
        assertTrue(store.pending(10).isEmpty(), "达到上限后不再待发布");
        assertEquals(1, store.deadLetters().size());
        assertEquals("bus down", store.deadLetters().get(0).lastError());
    }

    @Test
    void appendWithSameEventIdIsIdempotent() {
        InMemoryOutboxStore store = new InMemoryOutboxStore();
        store.append(ev("e1"), T0);
        store.append(ev("e1"), T0);
        assertEquals(1, store.pending(10).size());
    }

    @Test
    void purgeRemovesSentAfterSevenDaysAndDeadAfterThirty() {
        InMemoryOutboxStore store = new InMemoryOutboxStore();
        store.append(ev("sent"), T0);
        store.markSent("sent", T0);
        store.append(ev("dead"), T0);
        store.markFailed("dead", "x", 1, T0);

        store.purge(T0.plusSeconds(8L * 24 * 3600));
        assertEquals(1, store.deadLetters().size(), "死信 8 天后仍保留");

        store.purge(T0.plusSeconds(31L * 24 * 3600));
        assertTrue(store.deadLetters().isEmpty(), "死信 30 天后清理");
    }
}
