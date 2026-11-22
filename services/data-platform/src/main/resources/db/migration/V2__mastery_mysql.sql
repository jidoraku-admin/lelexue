-- 掌握判定（#92）。eventId 格式 <subject>:<userId>:<knowledgePointId>:<level>，列宽扩至 128。

ALTER TABLE outbox_event             MODIFY event_id VARCHAR(128) NOT NULL;
ALTER TABLE consumer_processed_event MODIFY event_id VARCHAR(128) NOT NULL;
ALTER TABLE consumer_grant           MODIFY event_id VARCHAR(128) NOT NULL;

-- 作答记录（判定输入）。attempt_id 为幂等键：同一作答重复提交只记录一次（#112 审核要求）。
CREATE TABLE mastery_attempt (
    id                 BIGINT       NOT NULL AUTO_INCREMENT,
    user_id            VARCHAR(64)  NOT NULL,
    subject            VARCHAR(32)  NOT NULL,
    knowledge_point_id VARCHAR(64)  NOT NULL,
    attempt_id         VARCHAR(64)  NOT NULL,
    item_type          VARCHAR(64)  NULL,
    correct            TINYINT(1)   NOT NULL,
    answered_at        DATETIME(3)  NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_attempt_id (user_id, subject, knowledge_point_id, attempt_id),
    KEY idx_attempt_key (user_id, subject, knowledge_point_id, answered_at, id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- 已发布的「首次达到」：业务唯一键 (userId, subject, knowledgePointId, level)。
-- first_attempt_id 记录触发首次达到的作答，重复提交时据此返回已有判定结果。
CREATE TABLE mastery_published (
    user_id            VARCHAR(64)  NOT NULL,
    subject            VARCHAR(32)  NOT NULL,
    knowledge_point_id VARCHAR(64)  NOT NULL,
    level              TINYINT      NOT NULL,
    event_id           VARCHAR(128) NOT NULL,
    first_attempt_id   VARCHAR(64)  NOT NULL,
    published_at       DATETIME(3)  NOT NULL,
    PRIMARY KEY (user_id, subject, knowledge_point_id, level)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
