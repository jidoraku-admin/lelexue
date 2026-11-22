-- 共享身份（P2 持久化草稿）。规则见 docs/architecture/shared/identity.md。
CREATE TABLE identity_account (
  user_id     VARCHAR(64)  NOT NULL PRIMARY KEY,
  kind        VARCHAR(32)  NOT NULL,
  login_name  VARCHAR(16)  NULL,
  parent_id   VARCHAR(64)  NULL,
  seat_limit  INT          NULL,
  CONSTRAINT uq_identity_login UNIQUE (login_name),
  CONSTRAINT fk_identity_parent FOREIGN KEY (parent_id) REFERENCES identity_account (user_id)
);

CREATE TABLE identity_entitlement (
  parent_id     VARCHAR(64) NOT NULL PRIMARY KEY,
  paid          BOOLEAN     NOT NULL,
  trial_active  BOOLEAN     NOT NULL,
  CONSTRAINT fk_identity_entitlement FOREIGN KEY (parent_id) REFERENCES identity_account (user_id)
);
