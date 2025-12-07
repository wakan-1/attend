/*
  # إصلاح سياسات RLS باستخدام دالة مخصصة

  1. الحل
    - إنشاء دالة للتحقق من دور المستخدم بدون recursion
    - استخدام SECURITY DEFINER لتجاوز RLS في الدالة
    - تبسيط السياسات
*/

-- حذف جميع السياسات القديمة
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Admins can read all users" ON users;
DROP POLICY IF EXISTS "Service role can insert users" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;
DROP POLICY IF EXISTS "Admins can delete users" ON users;

DROP POLICY IF EXISTS "Users can read own records" ON attendance_records;
DROP POLICY IF EXISTS "Admins can read all records" ON attendance_records;
DROP POLICY IF EXISTS "Users can insert own records" ON attendance_records;
DROP POLICY IF EXISTS "Users can update own records" ON attendance_records;
DROP POLICY IF EXISTS "Admins can delete records" ON attendance_records;

-- إنشاء دالة للتحقق من دور المستخدم (بدون RLS)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role
  FROM users
  WHERE id = auth.uid();
  
  RETURN user_role = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- سياسات جدول users
CREATE POLICY "Enable read for own data"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id OR is_admin());

CREATE POLICY "Enable insert for authenticated"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Enable update for own data or admin"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id OR is_admin())
  WITH CHECK (auth.uid() = id OR is_admin());

CREATE POLICY "Enable delete for admin"
  ON users FOR DELETE
  TO authenticated
  USING (is_admin());

-- سياسات جدول attendance_records
CREATE POLICY "Enable read for own records or admin"
  ON attendance_records FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR is_admin());

CREATE POLICY "Enable insert for own records"
  ON attendance_records FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Enable update for own records"
  ON attendance_records FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Enable delete for admin"
  ON attendance_records FOR DELETE
  TO authenticated
  USING (is_admin());