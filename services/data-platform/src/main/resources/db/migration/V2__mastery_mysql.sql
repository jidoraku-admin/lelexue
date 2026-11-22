-- 掌握判定（#92）。eventId 格式 <subject>:<userId>:<knowledgePointId>:<level>，列宽扩至 128。

ALTER TABLE outbox_event             MODIFY event_id VARCHAR(128) NOT NULL;
ALTER TABLE consumer_processed_event MODIFY event_id VARCHAR(128) NOT NULL;
ALTER TABLE consumer_grant           MODIFY event_id VARCHAR(128) NOT NULL;

-- 作答记录（判定输入）。
CREATE TABLE mastery_attempt (
    id                 BIGINT       NOT NULL AUTO_INCREMENT,
    user_id            VARCHAR(64)  NOT NULL,
    subject            VARCHAR(32)  NOT NULL,
    knowledge_point_id VARCHAR(64)  NOT NULL,
    item_type          VARCHAR(64)  NULL,
    correct            TINYINT(1)   NOT NULL,
    answered_at        DATETIME(3)  NOT NULL,
    PRIMARY KEY (id),
    KEY idx_attempt_key (user_id, subject, knowledge_point_id, answered_at, id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- 已发布的「首次达到」：业务唯一键 (userId, subject, knowledgePointId, level)。
CREATE TABLE mastery_published (
    user_id            VARCHAR(64)  NOT NULL,
    subject            VARCHAR(32)  NOT NULL,
    knowledge_point_id VARCHAR(64)  NOT NULL,
    level              TINYINT      NOT NULL,
    event_id           VARCHAR(128) NOT NULL,
    published_at       DATETIME(3)  NOT NULL,
    PRIMARY KEY (user_id, subject, knowledge_point_id, level)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
