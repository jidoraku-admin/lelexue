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
        return new AnswerAttempt("att-" + sec, correct, null, T0.plusSeconds(sec));
    }

    private List<MasteryChangedEvent> feed(String user, boolean... results) {
        List<MasteryChangedEvent> all = new java.util.ArrayList<>();
        for (int i = 0; i < results.length; i++) {
            all.addAll(svc.record(user, KP, ans(results[i], i)));
        }
        return all;
    }

    @Test
    void duplicateSubmitReturnsExistingResultWithoutRepublishing() {
        feed("u6", true, true, true, true);
        AnswerAttempt trigger = ans(true, 4);
        List<MasteryChangedEvent> first = svc.record("u6", KP, trigger);
        assertEquals(1, first.size());

        List<MasteryChangedEvent> retry = svc.record("u6", KP, trigger);
        assertEquals(1, retry.size(), "重复提交返回已有判定结果");
        assertEquals(first.get(0).eventId(), retry.get(0).eventId());
        assertEquals(5, count("SELECT COUNT(*) FROM mastery_attempt WHERE user_id = 'u6'"), "重复提交不重复插入");
        assertEquals(1, count("SELECT COUNT(*) FROM outbox_event WHERE event_id = 'math:u6:math.g3.v1.u01.k001:1'"),
                "重复提交不重复发布");
    }

    @Test
    void duplicatedAnswersDoNotInflateTheWindow() {
        // 最近 5 题正确率为 2/5，未达 0.8。重复提交 a4（正确）若被计数，窗口会被虚高。
        feed("u7", true, false, false, true, false);
        AnswerAttempt a4 = new AnswerAttempt("att-3", true, null, T0.plusSeconds(3));
        for (int i = 0; i < 5; i++) {
            assertTrue(svc.record("u7", KP, a4).isEmpty());
        }
        assertEquals(5, count("SELECT COUNT(*) FROM mastery_attempt WHERE user_id = 'u7'"));
        assertEquals(0, count("SELECT COUNT(*) FROM outbox_event"));
    }

    @Test
    void overlongUserIdIsRejectedBeforeAnyWrite() {
        String longUser = "u".repeat(65);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> svc.record(longUser, KP, ans(true, 0)));
        assertTrue(ex.getMessage().contains("userId") && ex.getMessage().contains("64"), ex.getMessage());
        assertEquals(0, count("SELECT COUNT(*) FROM mastery_attempt"), "校验失败时不写入作答");
    }

    @Test
    void overlongEventIdIsRejectedBeforeAnyWrite() {
        String longSubject = "a".repeat(32);
        KnowledgePointId longKp = new KnowledgePointId(longSubject + ".g3.v1.u01.k001");
        MysqlMasteryService longSvc = new MysqlMasteryService(ds, CLOCK, List.of(
                new MasteryRule(longSubject, 1, null, new BigDecimal("0.8"), 1, WindowKind.ATTEMPT)));
        String longUser = "u".repeat(50);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> longSvc.record(longUser, longKp, ans(true, 0)));
        assertTrue(ex.getMessage().contains("eventId") && ex.getMessage().contains("128"), ex.getMessage());
        assertEquals(0, count("SELECT COUNT(*) FROM mastery_attempt"), "eventId 超长时作答不得写入");
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
