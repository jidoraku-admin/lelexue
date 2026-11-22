package jidoraku.lelexue.dataplatform;

import static org.junit.jupiter.api.Assertions.*;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.concurrent.atomic.AtomicInteger;
import javax.sql.DataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** 发件箱 → 投递 → 消费端的端到端行为：至少一次投递、失败重试、超限死信、经验只发放一次。 */
class OutboxDeliveryIntegrationTest {

    private static final Instant T0 = Instant.parse("2026-11-22T10:00:00Z");
    private static final Clock CLOCK = Clock.fixed(T0, ZoneOffset.UTC);
    private DataSource ds;
    private JdbcOutboxStore outbox;

    @BeforeEach
    void setUp() {
        ds = MysqlTestDatabase.reset();
        outbox = new JdbcOutboxStore(ds);
    }

    private static MasteryChangedEvent ev(String id) {
        return new MasteryChangedEvent(id, "u1", "math", new KnowledgePointId("math.g3.v1.u01.k001"), 1, T0);
    }

    @Test
    void transientFailureIsRetriedAndGrantedExactlyOnce() {
        outbox.append(ev("e1"), T0);
        JdbcConsumerDedupe consumer = new JdbcConsumerDedupe(ds, CLOCK);
        AtomicInteger grants = new AtomicInteger();
        AtomicInteger calls = new AtomicInteger();

        OutboxPublisher p = new OutboxPublisher(outbox, e -> {
            if (calls.incrementAndGet() == 1) throw new IllegalStateException("bus timeout");
            if (consumer.accept(e)) grants.incrementAndGet();
        }, 10, 5, CLOCK);

        assertEquals(0, p.pollOnce(), "第一次投递失败");
        assertEquals(1, p.pollOnce(), "第二次投递成功");
        assertEquals(0, p.pollOnce(), "已发布，不再投递");
        assertEquals(1, grants.get());
        assertEquals(2, calls.get());
    }

    @Test
    void redeliveryAfterConsumerCrashDoesNotDoubleGrant() {
        outbox.append(ev("e1"), T0);
        JdbcConsumerDedupe consumer = new JdbcConsumerDedupe(ds, CLOCK);
        assertTrue(consumer.accept(ev("e1")));
        // 模拟发布方未收到确认，事件被再次投递
        new OutboxPublisher(outbox, e -> consumer.accept(e), 10, 5, CLOCK).pollOnce();
        assertFalse(new JdbcConsumerDedupe(ds, CLOCK).accept(ev("e1")));
    }

    @Test
    void persistentFailureEndsInDeadLetter() {
        outbox.append(ev("e1"), T0);
        OutboxPublisher p = new OutboxPublisher(outbox, e -> { throw new IllegalStateException("down"); }, 10, 3, CLOCK);
        for (int i = 0; i < 3; i++) p.pollOnce();
        assertTrue(outbox.pending(10).isEmpty());
        assertEquals(1, outbox.deadLetters().size());
        assertEquals(3, outbox.deadLetters().get(0).attempts());
    }

    @Test
    void consumerFailureRollsBackAndEventCanBeRedelivered() {
        // user_id 超过 64 字符，consumer_grant 写入失败（严格模式）。整体回滚，事件不得被记为已处理。
        JdbcConsumerDedupe consumer = new JdbcConsumerDedupe(ds, CLOCK);
        String tooLongUser = "u".repeat(65);
        MasteryChangedEvent broken = new MasteryChangedEvent("e1", tooLongUser, "math",
                new KnowledgePointId("math.g3.v1.u01.k001"), 1, T0);
        assertThrows(IllegalStateException.class, () -> consumer.accept(broken));

        // 同一 eventId 修正后重投：应可以正常处理并发放一次
        assertTrue(consumer.accept(ev("e1")), "回滚后重投应成功发放");
        assertFalse(consumer.accept(ev("e1")), "再次重投不得重复发放");
    }
}
