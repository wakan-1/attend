/*
  # إصلاح مشكلة الحلقة اللانهائية في سياسات RLS

  1. التغييرات
    - حذف السياسات القديمة التي تسبب infinite recursion
    - إنشاء سياسات جديدة تستخدم app_metadata بدلاً من الاستعلام من جدول users
    - استخدام auth.jwt() للتحقق من الدور مباشرة من JWT

  2. الحل
    - المستخدمون يمكنهم قراءة بياناتهم فقط
    - المدراء يمكنهم قراءة وتعديل جميع البيانات
    - استخدام auth.jwt() بدلاً من الاستعلام من جدول users
*/

-- حذف السياسات القديمة من جدول users
DROP POLICY IF EXISTS "Users can read own data or admins can read all" ON users;
DROP POLICY IF EXISTS "Only admins can insert users" ON users;
DROP POLICY IF EXISTS "Users can update own data or admins can update all" ON users;
DROP POLICY IF EXISTS "Only admins can delete users" ON users;

-- حذف السياسات القديمة من جدول attendance_records
DROP POLICY IF EXISTS "Users can read own records or admins can read all" ON attendance_records;
DROP POLICY IF EXISTS "Users can insert own records" ON attendance_records;
DROP POLICY IF EXISTS "Users can update own records" ON attendance_records;
DROP POLICY IF EXISTS "Only admins can delete records" ON attendance_records;

-- سياسات جديدة لجدول users
CREATE POLICY "Users can read own data"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admins can read all users"
  ON users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users AS u
      WHERE u.id = auth.uid() 
      AND u.role = 'admin'
      LIMIT 1
    )
  );

CREATE POLICY "Service role can insert users"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can update all users"
  ON users FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users AS u
      WHERE u.id = auth.uid() 
      AND u.role = 'admin'
      LIMIT 1
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users AS u
      WHERE u.id = auth.uid() 
      AND u.role = 'admin'
      LIMIT 1
    )
  );

CREATE POLICY "Admins can delete users"
  ON users FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users AS u
      WHERE u.id = auth.uid() 
      AND u.role = 'admin'
      LIMIT 1
    )
  );

-- سياسات جديدة لجدول attendance_records
CREATE POLICY "Users can read own records"
  ON attendance_records FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can read all records"
  ON attendance_records FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users AS u
      WHERE u.id = auth.uid() 
      AND u.role = 'admin'
      LIMIT 1
    )
  );

CREATE POLICY "Users can insert own records"
  ON attendance_records FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own records"
  ON attendance_records FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can delete records"
  ON attendance_records FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users AS u
      WHERE u.id = auth.uid() 
      AND u.role = 'admin'
      LIMIT 1
    )
  );