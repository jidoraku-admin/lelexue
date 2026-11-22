package jidoraku.lelexue.dataplatform;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.Clock;
import javax.sql.DataSource;

/**
 * 消费端去重的 MySQL 实现。eventId 登记与经验发放在同一事务内完成：
 * 处理失败则整体回滚，事件未被记为已处理，可以安全重投。重启后去重仍然有效。
 */
public final class JdbcConsumerDedupe implements ConsumerGate {

    private final DataSource dataSource;
    private final Clock clock;

    public JdbcConsumerDedupe(DataSource dataSource, Clock clock) {
        this.dataSource = dataSource;
        this.clock = clock;
    }

    @Override
    public boolean accept(MasteryChangedEvent e) {
        try (Connection c = dataSource.getConnection()) {
            c.setAutoCommit(false);
            try {
                // 注意：不用 INSERT IGNORE，它会把数据截断等错误降级为警告，导致静默丢失。只把主键冲突视为「已存在」。
                boolean firstSeen;
                try (PreparedStatement ps = c.prepareStatement(
                        "INSERT INTO consumer_processed_event (event_id, processed_at) VALUES (?, ?)")) {
                    ps.setString(1, e.eventId());
                    ps.setObject(2, JdbcOutboxStore.utc(clock.instant()));
                    ps.executeUpdate();
                    firstSeen = true;
                } catch (SQLException dup) {
                    if (!JdbcOutboxStore.isDuplicateKey(dup)) throw dup;
                    firstSeen = false;
                }
                if (!firstSeen) {
                    c.rollback();
                    return false;
                }
                boolean granted;
                try (PreparedStatement ps = c.prepareStatement("""
                        INSERT INTO consumer_grant
                          (user_id, subject, knowledge_point_id, level, event_id, granted_at)
                        VALUES (?, ?, ?, ?, ?, ?)""")) {
                    ps.setString(1, e.userId());
                    ps.setString(2, e.subject());
                    ps.setString(3, e.knowledgePointId().value());
                    ps.setInt(4, e.level());
                    ps.setString(5, e.eventId());
                    ps.setObject(6, JdbcOutboxStore.utc(clock.instant()));
                    ps.executeUpdate();
                    granted = true;
                } catch (SQLException dup) {
                    if (!JdbcOutboxStore.isDuplicateKey(dup)) throw dup;
                    granted = false;
                }
                c.commit();
                return granted;
            } catch (SQLException | RuntimeException ex) {
                c.rollback();
                throw ex;
            } finally {
                c.setAutoCommit(true);
            }
        } catch (SQLException ex) {
            throw new IllegalStateException("消费端处理失败，事件未登记，可重投", ex);
        }
    }
}
