-- let users create records via the UI.
CREATE TABLE UserSNPGenotype (
    user_id   INTEGER NOT NULL,
    snp_id    INTEGER NOT NULL,
    unigty_id INTEGER,
    PRIMARY KEY (user_id, snp_id)
)

go
