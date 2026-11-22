package jidoraku.lelexue.dataplatform;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import javax.sql.DataSource;

/**
 * 记录一次作答，并在某条规则首次满足时发布一次 MasteryChanged。
 * 作答写入、判定、「已发布」登记与发件箱写入在同一事务内完成。
 * 同一 attemptId 重复提交时不重复计数、不重复发布，返回该作答已产生的判定结果。
 */
public final class MysqlMasteryService {

    /** 列宽上限（V1/V2 迁移）。 */
    static final int USER_ID_MAX = 64;
    static final int SUBJECT_MAX = 32;
    static final int KNOWLEDGE_POINT_ID_MAX = 64;
    static final int ATTEMPT_ID_MAX = 64;

    private final DataSource dataSource;
    private final Clock clock;
    private final List<MasteryRule> rules;
    private final JdbcOutboxStore outbox;

    public MysqlMasteryService(DataSource dataSource, Clock clock, List<MasteryRule> rules) {
        this.dataSource = dataSource;
        this.clock = clock;
        this.rules = List.copyOf(rules);
        this.outbox = new JdbcOutboxStore(dataSource);
    }

    /**
     * 记录作答。返回本次新发布的事件；若 attemptId 为重复提交，返回该作答先前已产生的事件（可能为空）。
     * 字段长度与 eventId 长度在进入事务前校验，超限时直接拒绝且不写入任何记录。
     */
    public List<MasteryChangedEvent> record(String userId, KnowledgePointId kp, AnswerAttempt attempt) {
        validate(userId, kp, attempt);
        for (MasteryRule rule : rules) {
            if (rule.subject().equals(kp.subject())) {
                MasteryEventIds.of(rule.subject(), userId, kp, rule.level()); // 事务外校验 eventId 长度
            }
        }
        Instant now = clock.instant();
        try (Connection c = dataSource.getConnection()) {
            c.setAutoCommit(false);
            try {
                List<MasteryChangedEvent> result = apply(c, userId, kp, attempt, now);
                c.commit();
                return result;
            } catch (SQLException | RuntimeException ex) {
                c.rollback();
                throw ex;
            } finally {
                c.setAutoCommit(true);
            }
        } catch (SQLException ex) {
            throw new IllegalStateException("掌握判定失败，作答与发布均已回滚", ex);
        }
    }

    private List<MasteryChangedEvent> apply(Connection c, String userId, KnowledgePointId kp,
                                            AnswerAttempt attempt, Instant now) throws SQLException {
        if (!insertAttempt(c, userId, kp, attempt)) {
            // 重复提交：不写入、不计数、不发布；返回首次提交时产生的判定结果。
            return findPublishedBy(c, userId, kp, attempt.attemptId());
        }
        List<AnswerAttempt> history = loadHistory(c, userId, kp);
        List<MasteryChangedEvent> published = new ArrayList<>();
        for (MasteryRule rule : rules) {
            if (!rule.subject().equals(kp.subject())) continue;
            if (!MasteryEvaluator.satisfied(rule, history)) continue;
            String eventId = MasteryEventIds.of(rule.subject(), userId, kp, rule.level());
            if (markPublished(c, userId, kp, rule.level(), eventId, attempt.attemptId(), now)) {
                MasteryChangedEvent e = new MasteryChangedEvent(
                        eventId, userId, rule.subject(), kp, rule.level(), now);
                outbox.appendInTx(c, e, now);
                published.add(e);
            }
        }
        return published;
    }

    /** 进入事务前的校验：字段长度与 eventId 长度，超限时给出字段名与上限。 */
    static void validate(String userId, KnowledgePointId kp, AnswerAttempt attempt) {
        if (kp == null) throw new IllegalArgumentException("knowledgePointId 不能为空");
        if (attempt == null) throw new IllegalArgumentException("attempt 不能为空");
        requireLength("userId", userId, USER_ID_MAX);
        requireLength("subject", kp.subject(), SUBJECT_MAX);
        requireLength("knowledgePointId", kp.value(), KNOWLEDGE_POINT_ID_MAX);
        requireLength("attemptId", attempt.attemptId(), ATTEMPT_ID_MAX);
        if (attempt.answeredAt() == null) throw new IllegalArgumentException("answeredAt 不能为空");
    }

    private static void requireLength(String field, String value, int max) {
        if (value == null || value.isEmpty()) {
            throw new IllegalArgumentException(field + " 不能为空");
        }
        if (value.length() > max) {
            throw new IllegalArgumentException(
                    field + " 长度为 " + value.length() + "，超过上限 " + max);
        }
    }

    /** 插入作答；attemptId 已存在时返回 false（幂等键冲突）。 */
    private static boolean insertAttempt(Connection c, String userId, KnowledgePointId kp, AnswerAttempt a)
            throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("""
                INSERT INTO mastery_attempt
                  (user_id, subject, knowledge_point_id, attempt_id, item_type, correct, answered_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)""")) {
            ps.setString(1, userId);
            ps.setString(2, kp.subject());
            ps.setString(3, kp.value());
            ps.setString(4, a.attemptId());
            ps.setString(5, a.itemType());
            ps.setBoolean(6, a.correct());
            ps.setObject(7, JdbcOutboxStore.utc(a.answeredAt()));
            ps.executeUpdate();
            return true;
        } catch (SQLException ex) {
            if (JdbcOutboxStore.isDuplicateKey(ex)) return false;
            throw ex;
        }
    }

    private static List<AnswerAttempt> loadHistory(Connection c, String userId, KnowledgePointId kp)
            throws SQLException {
        List<AnswerAttempt> out = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement("""
                SELECT attempt_id, correct, item_type, answered_at FROM mastery_attempt
                WHERE user_id = ? AND subject = ? AND knowledge_point_id = ?
                ORDER BY answered_at, id""")) {
            ps.setString(1, userId);
            ps.setString(2, kp.subject());
            ps.setString(3, kp.value());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.add(new AnswerAttempt(
                            rs.getString("attempt_id"),
                            rs.getBoolean("correct"),
                            rs.getString("item_type"),
                            JdbcOutboxStore.fromUtc(rs.getObject("answered_at", LocalDateTime.class))));
                }
            }
        }
        return out;
    }

    /** 业务键 (userId, subject, knowledgePointId, level) 首次登记返回 true；已存在返回 false。 */
    private static boolean markPublished(Connection c, String userId, KnowledgePointId kp, int level,
                                         String eventId, String firstAttemptId, Instant now) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("""
                INSERT INTO mastery_published
                  (user_id, subject, knowledge_point_id, level, event_id, first_attempt_id, published_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)""")) {
            ps.setString(1, userId);
            ps.setString(2, kp.subject());
            ps.setString(3, kp.value());
            ps.setInt(4, level);
            ps.setString(5, eventId);
            ps.setString(6, firstAttemptId);
            ps.setObject(7, JdbcOutboxStore.utc(now));
            ps.executeUpdate();
            return true;
        } catch (SQLException ex) {
            if (JdbcOutboxStore.isDuplicateKey(ex)) return false;
            throw ex;
        }
    }

    /** 查询由该作答触发的发布记录，用于重复提交时返回已有结果。 */
    private static List<MasteryChangedEvent> findPublishedBy(Connection c, String userId, KnowledgePointId kp,
                                                            String attemptId) throws SQLException {
        List<MasteryChangedEvent> out = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement("""
                SELECT event_id, level, published_at FROM mastery_published
                WHERE user_id = ? AND subject = ? AND knowledge_point_id = ? AND first_attempt_id = ?
                ORDER BY level""")) {
            ps.setString(1, userId);
            ps.setString(2, kp.subject());
            ps.setString(3, kp.value());
            ps.setString(4, attemptId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.add(new MasteryChangedEvent(
                            rs.getString("event_id"),
                            userId,
                            kp.subject(),
                            kp,
                            rs.getInt("level"),
                            JdbcOutboxStore.fromUtc(rs.getObject("published_at", LocalDateTime.class))));
                }
            }
        }
        return out;
    }
}
