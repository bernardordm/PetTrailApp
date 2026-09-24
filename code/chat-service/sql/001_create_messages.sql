CREATE TABLE IF NOT EXISTS messages (
  identifier    VARCHAR PRIMARY KEY,
  tour_id       VARCHAR NOT NULL REFERENCES tours(identifier),
  sender_id     VARCHAR NOT NULL REFERENCES users(identifier),
  content       TEXT NOT NULL,
  sent_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  delivered_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_tour_id ON messages(tour_id);
CREATE INDEX IF NOT EXISTS idx_messages_tour_sent ON messages(tour_id, sent_at);