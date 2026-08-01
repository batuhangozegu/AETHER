-- NOTE: `direction` is a plain SMALLINT (ordinal), not a native Postgres enum
-- type, to match how Hibernate actually maps unannotated Java enums
-- elsewhere in this schema (see orders.status, exchange_keys.exchange_name).
CREATE TABLE price_alarms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    symbol VARCHAR(20) NOT NULL,
    target_price NUMERIC(20,8) NOT NULL,
    direction SMALLINT NOT NULL,
    triggered BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
