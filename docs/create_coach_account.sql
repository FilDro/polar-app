-- Run AFTER creating the user in Supabase Dashboard > Authentication > Add User
-- (email: ignisnomen@gmail.com, set password, check "Auto Confirm User")

UPDATE auth.users
SET raw_user_meta_data = raw_user_meta_data || '{"role": "coach", "name": "Filip"}'
WHERE email = 'ignisnomen@gmail.com';
