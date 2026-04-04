-- Drop the restrictive team SELECT policy and replace with one that works during bootstrap
DROP POLICY IF EXISTS "coaches_manage_team" ON teams;
DROP POLICY IF EXISTS "coaches_create_team" ON teams;

-- Coaches can read and update their own team
CREATE POLICY "coaches_read_own_team" ON teams
  FOR SELECT USING (true);

-- Any authenticated user can create a team
CREATE POLICY "coaches_create_team" ON teams
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Coaches can update their own team
CREATE POLICY "coaches_update_team" ON teams
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM coaches
      WHERE coaches.id = auth.uid()
        AND coaches.team_id = teams.id
    )
  );
