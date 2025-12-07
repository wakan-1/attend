/*
  # إنشاء نظام تسجيل الحضور والانصراف

  1. الجداول الجديدة
    - `users` - جدول المستخدمين
      - `id` (uuid, primary key) - معرف المستخدم من Auth
      - `email` (text) - البريد الإلكتروني
      - `full_name` (text) - الاسم الكامل
      - `employee_id` (text, unique) - رقم الموظف
      - `role` (text) - دور المستخدم (admin/user)
      - `is_active` (boolean) - حالة المستخدم
      - `created_at` (timestamptz) - تاريخ الإنشاء
      - `updated_at` (timestamptz) - تاريخ آخر تحديث
    
    - `attendance_records` - جدول سجلات الحضور
      - `id` (uuid, primary key) - معرف السجل
      - `user_id` (uuid, foreign key) - معرف المستخدم
      - `date` (date) - التاريخ
      - `check_in` (timestamptz) - وقت الحضور
      - `check_out` (timestamptz) - وقت الانصراف
      - `check_in_location` (jsonb) - موقع الحضور
      - `check_out_location` (jsonb) - موقع الانصراف
      - `total_hours` (numeric) - إجمالي الساعات
      - `created_at` (timestamptz) - تاريخ الإنشاء
      - `updated_at` (timestamptz) - تاريخ آخر تحديث

  2. الأمان (RLS Policies)
    - تفعيل RLS على جميع الجداول
    - المستخدمون يمكنهم قراءة بياناتهم فقط
    - المدراء يمكنهم قراءة وتعديل جميع البيانات
    - المستخدمون يمكنهم تسجيل حضورهم وانصرافهم

  3. الدوال (Functions)
    - دالة لحساب إجمالي ساعات العمل تلقائياً
*/

-- إنشاء جدول المستخدمين
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  employee_id text UNIQUE NOT NULL,
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- إنشاء جدول سجلات الحضور
CREATE TABLE IF NOT EXISTS attendance_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date date NOT NULL,
  check_in timestamptz,
  check_out timestamptz,
  check_in_location jsonb,
  check_out_location jsonb,
  total_hours numeric(5,2),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, date)
);

-- إنشاء فهارس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance_records(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_records(date);
CREATE INDEX IF NOT EXISTS idx_users_employee_id ON users(employee_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- دالة لحساب إجمالي ساعات العمل
CREATE OR REPLACE FUNCTION calculate_total_hours()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.check_in IS NOT NULL AND NEW.check_out IS NOT NULL THEN
    NEW.total_hours := EXTRACT(EPOCH FROM (NEW.check_out - NEW.check_in)) / 3600;
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger لحساب الساعات تلقائياً
DROP TRIGGER IF EXISTS calculate_hours_trigger ON attendance_records;
CREATE TRIGGER calculate_hours_trigger
  BEFORE INSERT OR UPDATE ON attendance_records
  FOR EACH ROW
  EXECUTE FUNCTION calculate_total_hours();

-- Trigger لتحديث updated_at في جدول المستخدمين
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- تفعيل RLS على جدول المستخدمين
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- سياسة قراءة: المستخدمون يمكنهم قراءة بياناتهم فقط، المدراء يمكنهم قراءة الجميع
CREATE POLICY "Users can read own data or admins can read all"
  ON users FOR SELECT
  TO authenticated
  USING (
    auth.uid() = id OR 
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- سياسة إدراج: فقط المدراء يمكنهم إضافة مستخدمين (من خلال Edge Function)
CREATE POLICY "Only admins can insert users"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- سياسة تحديث: المستخدمون يمكنهم تحديث بياناتهم، المدراء يمكنهم تحديث الجميع
CREATE POLICY "Users can update own data or admins can update all"
  ON users FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = id OR 
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  )
  WITH CHECK (
    auth.uid() = id OR 
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- سياسة حذف: فقط المدراء يمكنهم حذف المستخدمين
CREATE POLICY "Only admins can delete users"
  ON users FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- تفعيل RLS على جدول سجلات الحضور
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

-- سياسة قراءة: المستخدمون يمكنهم قراءة سجلاتهم فقط، المدراء يمكنهم قراءة الجميع
CREATE POLICY "Users can read own records or admins can read all"
  ON attendance_records FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR 
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- سياسة إدراج: المستخدمون يمكنهم إضافة سجلاتهم فقط
CREATE POLICY "Users can insert own records"
  ON attendance_records FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- سياسة تحديث: المستخدمون يمكنهم تحديث سجلاتهم فقط
CREATE POLICY "Users can update own records"
  ON attendance_records FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- سياسة حذف: فقط المدراء يمكنهم حذف السجلات
CREATE POLICY "Only admins can delete records"
  ON attendance_records FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );