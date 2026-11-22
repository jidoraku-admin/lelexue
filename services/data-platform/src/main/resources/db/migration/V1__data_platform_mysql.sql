-- 数据平台 V1（MySQL 8，#92）。时间统一存 UTC，DATETIME(3)。

-- 发件箱：与业务写入同一事务写入；轮询发布。
CREATE TABLE outbox_event (
    event_id           VARCHAR(64)  NOT NULL,
    user_id            VARCHAR(64)  NOT NULL,
    subject            VARCHAR(32)  NOT NULL,
    knowledge_point_id VARCHAR(64)  NOT NULL,
    level              TINYINT      NOT NULL,
    achieved_at        DATETIME(3)  NOT NULL,
    status             VARCHAR(16)  NOT NULL,
    attempts           INT          NOT NULL DEFAULT 0,
    last_error         VARCHAR(512) NULL,
    created_at         DATETIME(3)  NOT NULL,
    updated_at         DATETIME(3)  NOT NULL,
    PRIMARY KEY (event_id),
    KEY idx_outbox_status_created (status, created_at)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- 消费端：已处理的 eventId（至少一次投递的去重键）。
CREATE TABLE consumer_processed_event (
    event_id     VARCHAR(64) NOT NULL,
    processed_at DATETIME(3) NOT NULL,
    PRIMARY KEY (event_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- 消费端：经验发放的业务唯一键，同一键只发放一次「首次达到」。
CREATE TABLE consumer_grant (
    user_id            VARCHAR(64) NOT NULL,
    subject            VARCHAR(32) NOT NULL,
    knowledge_point_id VARCHAR(64) NOT NULL,
    level              TINYINT     NOT NULL,
    event_id           VARCHAR(64) NOT NULL,
    granted_at         DATETIME(3) NOT NULL,
    PRIMARY KEY (user_id, subject, knowledge_point_id, level)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
