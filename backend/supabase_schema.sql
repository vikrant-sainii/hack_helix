-- Run this in your Supabase SQL Editor once.
-- This creates the isl_glosses table used by FastAPI /enrich.

CREATE TABLE IF NOT EXISTS isl_glosses (
  gloss      TEXT PRIMARY KEY,          -- sign name e.g. "LIFE", "MY", "DANGER"
  duration   FLOAT NOT NULL,            -- duration in SECONDS (never ms here)
  keyframes  JSONB NOT NULL DEFAULT '[]',
  nmm        JSONB NOT NULL DEFAULT '{}'
);

-- Enable Row Level Security (RLS)
ALTER TABLE isl_glosses ENABLE ROW LEVEL SECURITY;

-- Allow public read (FastAPI uses anon key)
CREATE POLICY "Public read isl_glosses"
ON isl_glosses
FOR SELECT
TO anon
USING (true);

-- Example of what a row looks like:
-- INSERT INTO isl_glosses (gloss, duration, keyframes, nmm) VALUES (
--   'LIFE',
--   1.5,
--   '[
--     {"time": 0.0, "RightHand": [0, 0, 0]},
--     {"time": 0.7, "RightHand": [0.5, 1.0, 0]},
--     {"time": 1.5, "RightHand": [1.0, 1.2, 0]}
--   ]',
--   '{"face": "serious", "head": "neutral"}'
-- );
