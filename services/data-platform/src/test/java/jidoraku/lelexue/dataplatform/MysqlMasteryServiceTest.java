package jidoraku.lelexue.dataplatform;

import static org.junit.jupiter.api.Assertions.*;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import javax.sql.DataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class MysqlMasteryServiceTest {

    private static final Instant T0 = Instant.parse("2026-11-22T10:00:00Z");
    private static final Clock CLOCK = Clock.fixed(T0, ZoneOffset.UTC);
    private static final KnowledgePointId KP = new KnowledgePointId("math.g3.v1.u01.k001");
    private DataSource ds;
    private MysqlMasteryService svc;

    @BeforeEach
    void setUp() {
        ds = MysqlTestDatabase.reset();
        // 1★：最近 5 题（全部题型），正确率 ≥ 0.8
        svc = new MysqlMasteryService(ds, CLOCK, List.of(
                new MasteryRule("math", 1, null, new BigDecimal("0.8"), 5, WindowKind.ATTEMPT)));
    }

    private AnswerAttempt ans(boolean correct, int sec) {
        return new AnswerAttempt(correct, null, T0.plusSeconds(sec));
    }

    private List<MasteryChangedEvent> feed(String user, boolean... results) {
        List<MasteryChangedEvent> all = new java.util.ArrayList<>();
        for (int i = 0; i < results.length; i++) {
            all.addAll(svc.record(user, KP, ans(results[i], i)));
        }
        return all;
    }

    @Test
    void publishesExactlyOncePerBusinessKey() {
        List<MasteryChangedEvent> published = feed("u1", true, true, true, true, true, true, true);
        assertEquals(1, published.size(), "首次满足只发布一次");
        assertEquals("math:u1:math.g3.v1.u01.k001:1", published.get(0).eventId());
        assertEquals(1, count("SELECT COUNT(*) FROM outbox_event"));
    }

    @Test
    void differentStudentsEachPublishTheirOwnEvent() {
        assertEquals(1, feed("u1", true, true, true, true, true).size());
        assertEquals(1, feed("u2", true, true, true, true, true).size(), "不同学生的同一知识点都应发布");
        assertEquals(2, count("SELECT COUNT(*) FROM mastery_published"));
    }

    @Test
    void notSatisfiedPublishesNothing() {
        assertTrue(feed("u3", false, false, false, true, true).isEmpty());
        assertEquals(0, count("SELECT COUNT(*) FROM outbox_event"));
    }

    @Test
    void publishedEventIsInOutboxWithSameEventId() {
        feed("u4", true, true, true, true, true);
        assertEquals(1, count("SELECT COUNT(*) FROM outbox_event WHERE event_id = 'math:u4:math.g3.v1.u01.k001:1'"));
    }

    private int count(String sql) {
        try (var c = ds.getConnection(); var ps = c.prepareStatement(sql); var rs = ps.executeQuery()) {
            rs.next();
            return rs.getInt(1);
        } catch (java.sql.SQLException e) {
            throw new IllegalStateException(e);
        }
    }
}
