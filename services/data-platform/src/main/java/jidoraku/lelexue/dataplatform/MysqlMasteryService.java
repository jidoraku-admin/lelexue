package jidoraku.lelexue.dataplatform;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import javax.sql.DataSource;

/**
 * 记录一次作答，并在某条规则首次满足时发布一次 MasteryChanged。
 * 作答写入、判定、「已发布」登记与发件箱写入在同一事务内完成。
 */
public final class MysqlMasteryService {

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

    /** 返回本次新发布的事件（若无则为空）。 */
    public List<MasteryChangedEvent> record(String userId, KnowledgePointId kp, AnswerAttempt attempt) {
        Instant now = clock.instant();
        List<MasteryChangedEvent> published = new ArrayList<>();
        try (Connection c = dataSource.getConnection()) {
            c.setAutoCommit(false);
            try {
                insertAttempt(c, userId, kp, attempt);
                List<AnswerAttempt> history = loadHistory(c, userId, kp);
                for (MasteryRule rule : rules) {
                    if (!rule.subject().equals(kp.subject())) continue;
                    if (!MasteryEvaluator.satisfied(rule, history)) continue;
                    if (markPublished(c, userId, kp, rule.level(), now)) {
                        MasteryChangedEvent e = new MasteryChangedEvent(
                                MasteryEventIds.of(rule.subject(), userId, kp, rule.level()),
                                userId, rule.subject(), kp, rule.level(), now);
                        outbox.appendInTx(c, e, now);
                        published.add(e);
                    }
                }
                c.commit();
            } catch (SQLException | RuntimeException ex) {
                c.rollback();
                throw ex;
            } finally {
                c.setAutoCommit(true);
            }
        } catch (SQLException ex) {
            throw new IllegalStateException("掌握判定失败，作答与发布均已回滚", ex);
        }
        return published;
    }

    private static void insertAttempt(Connection c, String userId, KnowledgePointId kp, AnswerAttempt a)
            throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("""
                INSERT INTO mastery_attempt
                  (user_id, subject, knowledge_point_id, item_type, correct, answered_at)
                VALUES (?, ?, ?, ?, ?, ?)""")) {
            ps.setString(1, userId);
            ps.setString(2, kp.subject());
            ps.setString(3, kp.value());
            ps.setString(4, a.itemType());
            ps.setBoolean(5, a.correct());
            ps.setObject(6, JdbcOutboxStore.utc(a.answeredAt()));
            ps.executeUpdate();
        }
    }

    private static List<AnswerAttempt> loadHistory(Connection c, String userId, KnowledgePointId kp)
            throws SQLException {
        List<AnswerAttempt> out = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement("""
                SELECT correct, item_type, answered_at FROM mastery_attempt
                WHERE user_id = ? AND subject = ? AND knowledge_point_id = ?
                ORDER BY answered_at, id""")) {
            ps.setString(1, userId);
            ps.setString(2, kp.subject());
            ps.setString(3, kp.value());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.add(new AnswerAttempt(
                            rs.getBoolean("correct"),
                            rs.getString("item_type"),
                            JdbcOutboxStore.fromUtc(rs.getObject("answered_at", java.time.LocalDateTime.class))));
                }
            }
        }
        return out;
    }

    /** 业务键 (userId, subject, knowledgePointId, level) 首次登记返回 true；已存在返回 false。 */
    private static boolean markPublished(Connection c, String userId, KnowledgePointId kp, int level, Instant now)
            throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("""
                INSERT INTO mastery_published
                  (user_id, subject, knowledge_point_id, level, event_id, published_at)
                VALUES (?, ?, ?, ?, ?, ?)""")) {
            ps.setString(1, userId);
            ps.setString(2, kp.subject());
            ps.setString(3, kp.value());
            ps.setInt(4, level);
            ps.setString(5, MasteryEventIds.of(kp.subject(), userId, kp, level));
            ps.setObject(6, JdbcOutboxStore.utc(now));
            ps.executeUpdate();
            return true;
        } catch (SQLException ex) {
            if (JdbcOutboxStore.isDuplicateKey(ex)) return false;
            throw ex;
        }
    }
}
