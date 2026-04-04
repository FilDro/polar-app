-- KINE team-management RPCs
-- Run this file manually in the Supabase SQL editor.

-- Assign an unaffiliated athlete to the coach's team
CREATE OR REPLACE FUNCTION assign_athlete_to_team(
  p_athlete_id UUID,
  p_team_id UUID
) RETURNS VOID AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM coaches WHERE id = auth.uid() AND team_id = p_team_id
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  UPDATE athletes SET team_id = p_team_id
  WHERE id = p_athlete_id AND team_id IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Remove athlete from team (coach only)
CREATE OR REPLACE FUNCTION remove_athlete_from_team(
  p_athlete_id UUID,
  p_team_id UUID
) RETURNS VOID AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM coaches WHERE id = auth.uid() AND team_id = p_team_id
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  UPDATE athletes SET team_id = NULL
  WHERE id = p_athlete_id AND team_id = p_team_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
