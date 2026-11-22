package jidoraku.lelexue.dataplatform;

import com.mysql.cj.jdbc.MysqlDataSource;
import javax.sql.DataSource;
import org.flywaydb.core.Flyway;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * 集成测试使用真实 MySQL 8（不使用 H2）。
 * 默认通过 Testcontainers 启动 mysql:8.0；若设置了环境变量 DP_TEST_MYSQL_URL（及 DP_TEST_MYSQL_USER、DP_TEST_MYSQL_PASSWORD），
 * 则连接该实例（适用于没有 Docker 的本地环境）。每次使用前会清空并重新迁移，请只指向专用的测试库。
 */
final class MysqlTestDatabase {

    private static MySQLContainer<?> container;
    private static DataSource dataSource;

    private MysqlTestDatabase() {
    }

    static synchronized DataSource reset() {
        if (dataSource == null) {
            dataSource = create();
        }
        Flyway flyway = Flyway.configure()
                .dataSource(dataSource)
                .cleanDisabled(false)
                .load();
        flyway.clean();
        flyway.migrate();
        return dataSource;
    }

    private static DataSource create() {
        String url = System.getenv("DP_TEST_MYSQL_URL");
        if (url != null && !url.isBlank()) {
            MysqlDataSource ds = new MysqlDataSource();
            ds.setURL(url);
            ds.setUser(System.getenv("DP_TEST_MYSQL_USER"));
            ds.setPassword(System.getenv("DP_TEST_MYSQL_PASSWORD"));
            return ds;
        }
        container = new MySQLContainer<>(DockerImageName.parse("mysql:8.0"))
                .withDatabaseName("dp_test");
        container.start();
        MysqlDataSource ds = new MysqlDataSource();
        ds.setURL(container.getJdbcUrl());
        ds.setUser(container.getUsername());
        ds.setPassword(container.getPassword());
        return ds;
    }
}
