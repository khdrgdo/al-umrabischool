-- Roles
CREATE TYPE public.app_role AS ENUM ('owner', 'principal', 'supervisor');
CREATE TYPE public.student_status AS ENUM ('active', 'transferred_out', 'withdrawn', 'graduated', 'suspended');
CREATE TYPE public.enrollment_type AS ENUM ('new', 'transfer_in', 'continuing');
CREATE TYPE public.enrollment_status AS ENUM ('active', 'promoted', 'repeated', 'transferred_out', 'withdrawn', 'graduated');

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  email text,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, UPDATE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);
GRANT SELECT, INSERT, DELETE ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;
CREATE OR REPLACE FUNCTION public.is_staff(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id)
$$;
CREATE OR REPLACE FUNCTION public.can_manage(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role IN ('owner','principal'))
$$;

CREATE POLICY "own profile or staff read" ON public.profiles FOR SELECT TO authenticated
  USING (id = auth.uid() OR public.is_staff(auth.uid()));
CREATE POLICY "own profile update" ON public.profiles FOR UPDATE TO authenticated
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY "read own roles or owner reads all" ON public.user_roles FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.has_role(auth.uid(), 'owner'));
CREATE POLICY "owner grants roles" ON public.user_roles FOR INSERT TO authenticated
  WITH CHECK (public.has_role(auth.uid(), 'owner'));
CREATE POLICY "owner revokes roles" ON public.user_roles FOR DELETE TO authenticated
  USING (public.has_role(auth.uid(), 'owner') AND user_id <> auth.uid());

-- Signup: profile + first user becomes owner
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name', NEW.email);
  IF NOT EXISTS (SELECT 1 FROM public.user_roles WHERE role = 'owner') THEN
    INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'owner');
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Audit log
CREATE TABLE public.audit_log (
  id bigserial PRIMARY KEY,
  table_name text NOT NULL,
  record_id text,
  action text NOT NULL,
  old_data jsonb,
  new_data jsonb,
  actor_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.audit_log TO authenticated;
GRANT ALL ON public.audit_log TO service_role;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "managers read audit" ON public.audit_log FOR SELECT TO authenticated
  USING (public.can_manage(auth.uid()));

CREATE OR REPLACE FUNCTION public.audit_trigger()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.audit_log (table_name, record_id, action, old_data, new_data, actor_id)
  VALUES (TG_TABLE_NAME,
    COALESCE((to_jsonb(NEW)->>'id'), (to_jsonb(OLD)->>'id')),
    TG_OP,
    CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) END,
    auth.uid());
  RETURN COALESCE(NEW, OLD);
END $$;

-- School structure
CREATE TABLE public.schools (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  stage text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.academic_years (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  name text NOT NULL,
  starts_on date,
  ends_on date,
  is_current boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (school_id, name)
);
CREATE UNIQUE INDEX one_current_year_per_school ON public.academic_years(school_id) WHERE is_current;
CREATE TABLE public.grades (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  name text NOT NULL,
  level_order int NOT NULL,
  UNIQUE (school_id, name),
  UNIQUE (school_id, level_order)
);
CREATE TABLE public.tracks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  grade_id uuid NOT NULL REFERENCES public.grades(id) ON DELETE RESTRICT,
  name text NOT NULL,
  UNIQUE (grade_id, name)
);
CREATE TABLE public.specializations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  track_id uuid NOT NULL REFERENCES public.tracks(id) ON DELETE RESTRICT,
  name text NOT NULL,
  UNIQUE (track_id, name)
);
CREATE TABLE public.sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  grade_id uuid NOT NULL REFERENCES public.grades(id) ON DELETE RESTRICT,
  track_id uuid REFERENCES public.tracks(id) ON DELETE RESTRICT,
  specialization_id uuid REFERENCES public.specializations(id) ON DELETE RESTRICT,
  name text NOT NULL,
  capacity int CHECK (capacity IS NULL OR capacity > 0),
  UNIQUE (academic_year_id, grade_id, name)
);
CREATE TABLE public.subjects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  name text NOT NULL,
  code text,
  is_active boolean NOT NULL DEFAULT true,
  UNIQUE (school_id, name)
);
CREATE TABLE public.teachers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  full_name text NOT NULL,
  phone text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.students (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE RESTRICT,
  student_number text NOT NULL UNIQUE,
  full_name text NOT NULL,
  gender text CHECK (gender IN ('male','female')),
  birth_date date,
  guardian_name text,
  guardian_phone text,
  status public.student_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.enrollments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  academic_year_id uuid NOT NULL REFERENCES public.academic_years(id) ON DELETE RESTRICT,
  section_id uuid NOT NULL REFERENCES public.sections(id) ON DELETE RESTRICT,
  enrollment_type public.enrollment_type NOT NULL,
  status public.enrollment_status NOT NULL DEFAULT 'active',
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (student_id, academic_year_id)
);

-- Enrollment section must belong to same academic year
CREATE OR REPLACE FUNCTION public.check_enrollment_year()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.sections s WHERE s.id = NEW.section_id AND s.academic_year_id = NEW.academic_year_id) THEN
    RAISE EXCEPTION 'الشعبة لا تتبع السنة الدراسية المحددة';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER enrollment_year_check BEFORE INSERT OR UPDATE ON public.enrollments
  FOR EACH ROW EXECUTE FUNCTION public.check_enrollment_year();

-- Grants, RLS, policies, audit for structure tables
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['schools','academic_years','grades','tracks','specializations','sections','subjects','teachers','students','enrollments'] LOOP
    EXECUTE format('GRANT SELECT, INSERT, UPDATE ON public.%I TO authenticated', t);
    EXECUTE format('GRANT ALL ON public.%I TO service_role', t);
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY "staff read" ON public.%I FOR SELECT TO authenticated USING (public.is_staff(auth.uid()))', t);
    EXECUTE format('CREATE POLICY "managers insert" ON public.%I FOR INSERT TO authenticated WITH CHECK (public.can_manage(auth.uid()))', t);
    EXECUTE format('CREATE POLICY "managers update" ON public.%I FOR UPDATE TO authenticated USING (public.can_manage(auth.uid())) WITH CHECK (public.can_manage(auth.uid()))', t);
    EXECUTE format('CREATE TRIGGER audit_%I AFTER INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.audit_trigger()', t, t);
  END LOOP;
END $$;
CREATE TRIGGER audit_user_roles AFTER INSERT OR DELETE ON public.user_roles FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();

-- Confirmed structure from requirements
DO $$
DECLARE s uuid; g3 uuid; sci uuid;
BEGIN
  INSERT INTO public.schools (name, stage) VALUES ('مدرسة العمرابي الثانوية', 'secondary') RETURNING id INTO s;
  INSERT INTO public.grades (school_id, name, level_order) VALUES
    (s, 'الصف الأول الثانوي', 1), (s, 'الصف الثاني الثانوي', 2);
  INSERT INTO public.grades (school_id, name, level_order) VALUES (s, 'الصف الثالث الثانوي', 3) RETURNING id INTO g3;
  INSERT INTO public.tracks (grade_id, name) VALUES (g3, 'المسار العلمي') RETURNING id INTO sci;
  INSERT INTO public.tracks (grade_id, name) VALUES (g3, 'المسار الأدبي');
  INSERT INTO public.specializations (track_id, name) VALUES (sci, 'أحياء'), (sci, 'حاسوب'), (sci, 'هندسية');
END $$;