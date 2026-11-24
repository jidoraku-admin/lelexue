package jidoraku.lelexue.dataplatform;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import javax.sql.DataSource;

/** 发件箱的 MySQL 实现（表结构见 V1 迁移）。单个轮询进程使用；多实例需另行加锁。 */
public final class JdbcOutboxStore implements OutboxStore {

    static final Duration SENT_RETENTION = Duration.ofDays(7);
    static final Duration DEAD_RETENTION = Duration.ofDays(30);

    private final DataSource dataSource;

    public JdbcOutboxStore(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public void append(MasteryChangedEvent e, Instant now) {
        try (Connection c = dataSource.getConnection()) {
            appendInTx(c, e, now);
        } catch (SQLException ex) {
            throw new IllegalStateException("outbox 写入失败", ex);
        }
    }

    /**
     * 在调用方的事务内写入发件箱（与业务写入同一事务，#92 方案）。
     * 同一 eventId 重复写入视为幂等；其他错误照常抛出。
     */
    public void appendInTx(Connection c, MasteryChangedEvent e, Instant now) {
        String sql = """
                INSERT INTO outbox_event
                  (event_id, user_id, subject, knowledge_point_id, level, achieved_at,
                   status, attempts, last_error, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, 'PENDING', 0, NULL, ?, ?)""";
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, e.eventId());
            ps.setString(2, e.userId());
            ps.setString(3, e.subject());
            ps.setString(4, e.knowledgePointId().value());
            ps.setInt(5, e.level());
            ps.setObject(6, utc(e.achievedAt()));
            ps.setObject(7, utc(now));
            ps.setObject(8, utc(now));
            ps.executeUpdate();
        } catch (SQLException ex) {
            if (!isDuplicateKey(ex)) throw new IllegalStateException("outbox 写入失败", ex);
        }
    }

    @Override
    public List<OutboxRecord> pending(int limit) {
        return query("""
                SELECT * FROM outbox_event WHERE status = 'PENDING'
                ORDER BY created_at, event_id LIMIT ?""", ps -> ps.setInt(1, limit));
    }

    @Override
    public void markSent(String eventId, Instant now) {
        execute("""
                UPDATE outbox_event SET status = 'SENT', attempts = attempts + 1,
                  last_error = NULL, updated_at = ? WHERE event_id = ?""", ps -> {
            ps.setObject(1, utc(now));
            ps.setString(2, eventId);
        });
    }

    @Override
    public void markFailed(String eventId, String reason, int maxAttempts, Instant now) {
        // 注意：MySQL 单表 UPDATE 按列顺序赋值，status 必须写在 attempts 之前，才能用旧的 attempts 判断。
        execute("""
                UPDATE outbox_event
                SET status = CASE WHEN attempts + 1 >= ? THEN 'DEAD' ELSE 'PENDING' END,
                    attempts = attempts + 1, last_error = ?, updated_at = ?
                WHERE event_id = ?""", ps -> {
            ps.setInt(1, maxAttempts);
            ps.setString(2, truncate(reason));
            ps.setObject(3, utc(now));
            ps.setString(4, eventId);
        });
    }

    @Override
    public void purge(Instant now) {
        execute("""
                DELETE FROM outbox_event
                WHERE (status = 'SENT' AND updated_at < ?) OR (status = 'DEAD' AND updated_at < ?)""", ps -> {
            ps.setObject(1, utc(now.minus(SENT_RETENTION)));
            ps.setObject(2, utc(now.minus(DEAD_RETENTION)));
        });
    }

    @Override
    public List<OutboxRecord> deadLetters() {
        return query("SELECT * FROM outbox_event WHERE status = 'DEAD' ORDER BY created_at, event_id", ps -> { });
    }

    private List<OutboxRecord> query(String sql, Binder binder) {
        try (Connection c = dataSource.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            binder.bind(ps);
            List<OutboxRecord> out = new ArrayList<>();
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.add(map(rs));
                }
            }
            return out;
        } catch (SQLException ex) {
            throw new IllegalStateException("outbox 查询失败", ex);
        }
    }

    private void execute(String sql, Binder binder) {
        try (Connection c = dataSource.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            binder.bind(ps);
            ps.executeUpdate();
        } catch (SQLException ex) {
            throw new IllegalStateException("outbox 写入失败", ex);
        }
    }

    private static OutboxRecord map(ResultSet rs) throws SQLException {
        MasteryChangedEvent event = new MasteryChangedEvent(
                rs.getString("event_id"),
                rs.getString("user_id"),
                rs.getString("subject"),
                new KnowledgePointId(rs.getString("knowledge_point_id")),
                rs.getInt("level"),
                fromUtc(rs.getObject("achieved_at", LocalDateTime.class)));
        return new OutboxRecord(
                event,
                OutboxRecord.Status.valueOf(rs.getString("status")),
                rs.getInt("attempts"),
                fromUtc(rs.getObject("created_at", LocalDateTime.class)),
                fromUtc(rs.getObject("updated_at", LocalDateTime.class)),
                rs.getString("last_error"));
    }

    /** MySQL 主键冲突的错误码（1062）。 */
    static boolean isDuplicateKey(SQLException ex) {
        return ex.getErrorCode() == 1062;
    }

    static LocalDateTime utc(Instant i) {
        return LocalDateTime.ofInstant(i, ZoneOffset.UTC);
    }

    static Instant fromUtc(LocalDateTime t) {
        return t.toInstant(ZoneOffset.UTC);
    }

    private static String truncate(String s) {
        if (s == null) return null;
        return s.length() <= 512 ? s : s.substring(0, 512);
    }

    @FunctionalInterface
    private interface Binder {
        void bind(PreparedStatement ps) throws SQLException;
    }
}
