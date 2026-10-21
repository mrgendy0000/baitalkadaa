-- New dedicated Neon database only. No existing project/schema is altered.
CREATE SCHEMA IF NOT EXISTS legal_private;
REVOKE ALL ON SCHEMA legal_private FROM PUBLIC;
CREATE TABLE IF NOT EXISTS legal_private.offices (
 id uuid PRIMARY KEY,
 email text UNIQUE NOT NULL,
 phone text NOT NULL,
 password_hash text NOT NULL,
 name text NOT NULL,
 lawyer_name text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 trial_start timestamptz NOT NULL DEFAULT now(),
 trial_end timestamptz NOT NULL DEFAULT (now() + interval '30 days'),
 is_active boolean NOT NULL DEFAULT true,
 is_admin boolean NOT NULL DEFAULT false,
 plan text NOT NULL DEFAULT 'trial_month'
);
CREATE UNIQUE INDEX IF NOT EXISTS legal_office_phone_unique ON legal_private.offices(phone);
CREATE TABLE IF NOT EXISTS legal_private.sessions (
 token_hash text PRIMARY KEY,
 office_id uuid NOT NULL REFERENCES legal_private.offices(id) ON DELETE CASCADE,
 expires_at timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS legal_private.state (
 office_id uuid PRIMARY KEY REFERENCES legal_private.offices(id) ON DELETE CASCADE,
 data jsonb NOT NULL DEFAULT '{}'::jsonb,
 version bigint NOT NULL DEFAULT 1,
 updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE legal_private.state ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_private.state FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS office_isolation ON legal_private.state;
CREATE POLICY office_isolation ON legal_private.state FOR ALL
 USING (office_id::text = current_setting('legal.office_id', true))
 WITH CHECK (office_id::text = current_setting('legal.office_id', true));
CREATE TABLE IF NOT EXISTS legal_private.limits (
 bucket text PRIMARY KEY,
 count integer NOT NULL DEFAULT 1,
 created_at timestamptz NOT NULL DEFAULT now()
);
REVOKE ALL ON ALL TABLES IN SCHEMA legal_private FROM PUBLIC;
