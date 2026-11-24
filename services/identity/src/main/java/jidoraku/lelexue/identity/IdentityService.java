package jidoraku.lelexue.identity;

import javax.sql.DataSource;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.regex.Pattern;

/**
 * 共享身份服务（持久化草稿，#23 P2）。
 *
 * 规则与 docs/architecture/shared/identity.md 一致：
 * - 家长账号默认最多 maxStudentsPerParent 名学生；班级或机构按 seat_limit 计价。
 * - 学生登录名 4–16 位小写字母或数字，全局唯一。
 * - 学生不能独立注册、付费；权益挂母账号，学生继承。
 * 席位计数在父账号行上加 FOR UPDATE 锁，保证并发创建学生时不超额。
 */
@Service
public final class IdentityService {

    private static final Pattern LOGIN_NAME = Pattern.compile("^[a-z0-9]{4,16}$");

    private final DataSource dataSource;
    private final int maxStudentsPerParent;

    public IdentityService(DataSource dataSource,
                           @Value("${identity.max-students-per-parent:3}") int maxStudentsPerParent) {
        this.dataSource = dataSource;
        this.maxStudentsPerParent = maxStudentsPerParent;
    }

    /** 登记母账号。seatLimit 为 null 表示家长账号，否则为班级或机构。 */
    public void registerParent(String userId, Integer seatLimit) {
        AccountKind kind = seatLimit == null ? AccountKind.PARENT : AccountKind.CLASS_OR_INSTITUTION;
        try (Connection c = dataSource.getConnection()) {
            c.setAutoCommit(false);
            try {
                insertAccount(c, userId, kind, null, null, seatLimit);
                try (PreparedStatement ps = c.prepareStatement(
                        "INSERT INTO identity_entitlement (parent_id, paid, trial_active) VALUES (?, FALSE, FALSE)")) {
                    ps.setString(1, userId);
                    ps.executeUpdate();
                }
                c.commit();
            } catch (SQLException e) {
                c.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw new IdentityException("register parent failed: " + e.getMessage());
        }
    }

    /** 由母账号创建学生账号，占用一个席位。 */
    public void createStudent(String parentId, String studentId, String loginName) {
        if (!LOGIN_NAME.matcher(loginName).matches()) {
            throw new IdentityException("login name must be 4-16 lowercase letters or digits");
        }
        try (Connection c = dataSource.getConnection()) {
            c.setAutoCommit(false);
            try {
                Integer seatLimit = lockParent(c, parentId);
                AccountKind parentKind = kindOf(c, parentId);
                if (parentKind == AccountKind.STUDENT) {
                    throw new IdentityException("students cannot create students");
                }
                int limit = seatLimit != null ? seatLimit : maxStudentsPerParent;
                if (countSeats(c, parentId) >= limit) {
                    throw new IdentityException("no seat left for this account");
                }
                insertAccount(c, studentId, AccountKind.STUDENT, loginName, parentId, null);
                c.commit();
            } catch (IdentityException e) {
                c.rollback();
                throw e;
            } catch (SQLException e) {
                c.rollback();
                throw new IdentityException("create student failed: " + e.getMessage());
            }
        } catch (SQLException e) {
            throw new IdentityException("connection failed: " + e.getMessage());
        }
    }

    /** 解除母子关系并释放席位。学生账号保留。 */
    public void unlink(String parentId, String studentId) {
        try (Connection c = dataSource.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "UPDATE identity_account SET parent_id = NULL WHERE user_id = ? AND parent_id = ? AND kind = 'STUDENT'")) {
            ps.setString(1, studentId);
            ps.setString(2, parentId);
            if (ps.executeUpdate() == 0) {
                throw new IdentityException("student does not belong to this parent");
            }
        } catch (SQLException e) {
            throw new IdentityException("unlink failed: " + e.getMessage());
        }
    }

    /** 已占用的席位数。 */
    public int seatsUsed(String parentId) {
        try (Connection c = dataSource.getConnection()) {
            return countSeats(c, parentId);
        } catch (SQLException e) {
            throw new IdentityException("seat count failed: " + e.getMessage());
        }
    }

    /** 设置母账号的权益。 */
    public void setEntitlement(String parentId, Entitlement entitlement) {
        try (Connection c = dataSource.getConnection()) {
            if (kindOf(c, parentId) == AccountKind.STUDENT) {
                throw new IdentityException("entitlement belongs to a parent account");
            }
            try (PreparedStatement ps = c.prepareStatement(
                    "UPDATE identity_entitlement SET paid = ?, trial_active = ? WHERE parent_id = ?")) {
                ps.setBoolean(1, entitlement.paid());
                ps.setBoolean(2, entitlement.trialActive());
                ps.setString(3, parentId);
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            throw new IdentityException("set entitlement failed: " + e.getMessage());
        }
    }

    /** 查询权益。学生返回其母账号的权益。 */
    public Entitlement getEntitlement(String userId) {
        try (Connection c = dataSource.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT e.paid, e.trial_active FROM identity_account a "
                             + "JOIN identity_entitlement e ON e.parent_id = "
                             + "CASE WHEN a.kind = 'STUDENT' THEN a.parent_id ELSE a.user_id END "
                             + "WHERE a.user_id = ?")) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Entitlement.NONE;
                }
                return new Entitlement(rs.getBoolean(1), rs.getBoolean(2));
            }
        } catch (SQLException e) {
            throw new IdentityException("get entitlement failed: " + e.getMessage());
        }
    }

    private static void insertAccount(Connection c, String userId, AccountKind kind,
                                      String loginName, String parentId, Integer seatLimit) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "INSERT INTO identity_account (user_id, kind, login_name, parent_id, seat_limit) VALUES (?, ?, ?, ?, ?)")) {
            ps.setString(1, userId);
            ps.setString(2, kind.name());
            ps.setString(3, loginName);
            ps.setString(4, parentId);
            if (seatLimit == null) {
                ps.setNull(5, java.sql.Types.INTEGER);
            } else {
                ps.setInt(5, seatLimit);
            }
            ps.executeUpdate();
        }
    }

    /** 对父账号加行锁并返回其席位上限（家长账号为 null）。 */
    private static Integer lockParent(Connection c, String parentId) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT seat_limit FROM identity_account WHERE user_id = ? FOR UPDATE")) {
            ps.setString(1, parentId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IdentityException("unknown account: " + parentId);
                }
                int value = rs.getInt(1);
                return rs.wasNull() ? null : value;
            }
        }
    }

    private static AccountKind kindOf(Connection c, String userId) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement("SELECT kind FROM identity_account WHERE user_id = ?")) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new IdentityException("unknown account: " + userId);
                }
                return AccountKind.valueOf(rs.getString(1));
            }
        }
    }

    private static int countSeats(Connection c, String parentId) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT COUNT(*) FROM identity_account WHERE parent_id = ? AND kind = 'STUDENT'")) {
            ps.setString(1, parentId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }
}
