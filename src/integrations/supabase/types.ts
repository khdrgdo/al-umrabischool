export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      academic_years: {
        Row: {
          created_at: string
          ends_on: string | null
          id: string
          is_current: boolean
          name: string
          school_id: string
          starts_on: string | null
        }
        Insert: {
          created_at?: string
          ends_on?: string | null
          id?: string
          is_current?: boolean
          name: string
          school_id: string
          starts_on?: string | null
        }
        Update: {
          created_at?: string
          ends_on?: string | null
          id?: string
          is_current?: boolean
          name?: string
          school_id?: string
          starts_on?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "academic_years_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      attendance_records: {
        Row: {
          id: string
          reason: string | null
          session_id: string
          status: string
          student_id: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          id?: string
          reason?: string | null
          session_id: string
          status?: string
          student_id: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          id?: string
          reason?: string | null
          session_id?: string
          status?: string
          student_id?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "attendance_records_session_id_fkey"
            columns: ["session_id"]
            isOneToOne: false
            referencedRelation: "attendance_sessions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "attendance_records_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "students"
            referencedColumns: ["id"]
          },
        ]
      }
      attendance_sessions: {
        Row: {
          academic_year_id: string
          attendance_date: string
          created_at: string
          created_by: string | null
          id: string
          section_id: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          academic_year_id: string
          attendance_date: string
          created_at?: string
          created_by?: string | null
          id?: string
          section_id: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          academic_year_id?: string
          attendance_date?: string
          created_at?: string
          created_by?: string | null
          id?: string
          section_id?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "attendance_sessions_academic_year_id_fkey"
            columns: ["academic_year_id"]
            isOneToOne: false
            referencedRelation: "academic_years"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "attendance_sessions_section_id_fkey"
            columns: ["section_id"]
            isOneToOne: false
            referencedRelation: "sections"
            referencedColumns: ["id"]
          },
        ]
      }
      audit_log: {
        Row: {
          action: string
          actor_id: string | null
          created_at: string
          id: number
          new_data: Json | null
          old_data: Json | null
          record_id: string | null
          table_name: string
        }
        Insert: {
          action: string
          actor_id?: string | null
          created_at?: string
          id?: number
          new_data?: Json | null
          old_data?: Json | null
          record_id?: string | null
          table_name: string
        }
        Update: {
          action?: string
          actor_id?: string | null
          created_at?: string
          id?: number
          new_data?: Json | null
          old_data?: Json | null
          record_id?: string | null
          table_name?: string
        }
        Relationships: []
      }
      enrollments: {
        Row: {
          academic_year_id: string
          created_at: string
          enrollment_type: Database["public"]["Enums"]["enrollment_type"]
          id: string
          notes: string | null
          section_id: string
          status: Database["public"]["Enums"]["enrollment_status"]
          student_id: string
        }
        Insert: {
          academic_year_id: string
          created_at?: string
          enrollment_type: Database["public"]["Enums"]["enrollment_type"]
          id?: string
          notes?: string | null
          section_id: string
          status?: Database["public"]["Enums"]["enrollment_status"]
          student_id: string
        }
        Update: {
          academic_year_id?: string
          created_at?: string
          enrollment_type?: Database["public"]["Enums"]["enrollment_type"]
          id?: string
          notes?: string | null
          section_id?: string
          status?: Database["public"]["Enums"]["enrollment_status"]
          student_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "enrollments_academic_year_id_fkey"
            columns: ["academic_year_id"]
            isOneToOne: false
            referencedRelation: "academic_years"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "enrollments_section_id_fkey"
            columns: ["section_id"]
            isOneToOne: false
            referencedRelation: "sections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "enrollments_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "students"
            referencedColumns: ["id"]
          },
        ]
      }
      grades: {
        Row: {
          id: string
          level_order: number
          name: string
          school_id: string
        }
        Insert: {
          id?: string
          level_order: number
          name: string
          school_id: string
        }
        Update: {
          id?: string
          level_order?: number
          name?: string
          school_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "grades_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      periods: {
        Row: {
          ends_at: string
          id: string
          is_break: boolean
          label: string
          period_order: number
          school_id: string
          starts_at: string
        }
        Insert: {
          ends_at: string
          id?: string
          is_break?: boolean
          label: string
          period_order: number
          school_id: string
          starts_at: string
        }
        Update: {
          ends_at?: string
          id?: string
          is_break?: boolean
          label?: string
          period_order?: number
          school_id?: string
          starts_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "periods_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          email: string | null
          full_name: string | null
          id: string
        }
        Insert: {
          created_at?: string
          email?: string | null
          full_name?: string | null
          id: string
        }
        Update: {
          created_at?: string
          email?: string | null
          full_name?: string | null
          id?: string
        }
        Relationships: []
      }
      school_days: {
        Row: {
          id: string
          school_id: string
          weekday: number
        }
        Insert: {
          id?: string
          school_id: string
          weekday: number
        }
        Update: {
          id?: string
          school_id?: string
          weekday?: number
        }
        Relationships: [
          {
            foreignKeyName: "school_days_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      schools: {
        Row: {
          created_at: string
          id: string
          is_active: boolean
          name: string
          stage: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_active?: boolean
          name: string
          stage: string
        }
        Update: {
          created_at?: string
          id?: string
          is_active?: boolean
          name?: string
          stage?: string
        }
        Relationships: []
      }
      section_timetables: {
        Row: {
          approved_at: string | null
          approved_by: string | null
          section_id: string
          status: Database["public"]["Enums"]["timetable_status"]
        }
        Insert: {
          approved_at?: string | null
          approved_by?: string | null
          section_id: string
          status?: Database["public"]["Enums"]["timetable_status"]
        }
        Update: {
          approved_at?: string | null
          approved_by?: string | null
          section_id?: string
          status?: Database["public"]["Enums"]["timetable_status"]
        }
        Relationships: [
          {
            foreignKeyName: "section_timetables_section_id_fkey"
            columns: ["section_id"]
            isOneToOne: true
            referencedRelation: "sections"
            referencedColumns: ["id"]
          },
        ]
      }
      sections: {
        Row: {
          academic_year_id: string
          capacity: number | null
          grade_id: string
          id: string
          name: string
          specialization_id: string | null
          track_id: string | null
        }
        Insert: {
          academic_year_id: string
          capacity?: number | null
          grade_id: string
          id?: string
          name: string
          specialization_id?: string | null
          track_id?: string | null
        }
        Update: {
          academic_year_id?: string
          capacity?: number | null
          grade_id?: string
          id?: string
          name?: string
          specialization_id?: string | null
          track_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "sections_academic_year_id_fkey"
            columns: ["academic_year_id"]
            isOneToOne: false
            referencedRelation: "academic_years"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sections_grade_id_fkey"
            columns: ["grade_id"]
            isOneToOne: false
            referencedRelation: "grades"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sections_specialization_id_fkey"
            columns: ["specialization_id"]
            isOneToOne: false
            referencedRelation: "specializations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sections_track_id_fkey"
            columns: ["track_id"]
            isOneToOne: false
            referencedRelation: "tracks"
            referencedColumns: ["id"]
          },
        ]
      }
      specializations: {
        Row: {
          id: string
          name: string
          track_id: string
        }
        Insert: {
          id?: string
          name: string
          track_id: string
        }
        Update: {
          id?: string
          name?: string
          track_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "specializations_track_id_fkey"
            columns: ["track_id"]
            isOneToOne: false
            referencedRelation: "tracks"
            referencedColumns: ["id"]
          },
        ]
      }
      student_status_history: {
        Row: {
          changed_at: string
          changed_by: string | null
          id: string
          new_status: Database["public"]["Enums"]["student_status"]
          old_status: Database["public"]["Enums"]["student_status"] | null
          reason: string | null
          student_id: string
        }
        Insert: {
          changed_at?: string
          changed_by?: string | null
          id?: string
          new_status: Database["public"]["Enums"]["student_status"]
          old_status?: Database["public"]["Enums"]["student_status"] | null
          reason?: string | null
          student_id: string
        }
        Update: {
          changed_at?: string
          changed_by?: string | null
          id?: string
          new_status?: Database["public"]["Enums"]["student_status"]
          old_status?: Database["public"]["Enums"]["student_status"] | null
          reason?: string | null
          student_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "student_status_history_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "students"
            referencedColumns: ["id"]
          },
        ]
      }
      students: {
        Row: {
          address: string | null
          birth_date: string | null
          created_at: string
          full_name: string
          gender: string | null
          guardian_name: string | null
          guardian_phone: string | null
          guardian_relation: string | null
          id: string
          national_id: string | null
          notes: string | null
          previous_school: string | null
          school_id: string
          status: Database["public"]["Enums"]["student_status"]
          student_number: string
          updated_at: string
        }
        Insert: {
          address?: string | null
          birth_date?: string | null
          created_at?: string
          full_name: string
          gender?: string | null
          guardian_name?: string | null
          guardian_phone?: string | null
          guardian_relation?: string | null
          id?: string
          national_id?: string | null
          notes?: string | null
          previous_school?: string | null
          school_id: string
          status?: Database["public"]["Enums"]["student_status"]
          student_number?: string
          updated_at?: string
        }
        Update: {
          address?: string | null
          birth_date?: string | null
          created_at?: string
          full_name?: string
          gender?: string | null
          guardian_name?: string | null
          guardian_phone?: string | null
          guardian_relation?: string | null
          id?: string
          national_id?: string | null
          notes?: string | null
          previous_school?: string | null
          school_id?: string
          status?: Database["public"]["Enums"]["student_status"]
          student_number?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "students_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      subjects: {
        Row: {
          code: string | null
          id: string
          is_active: boolean
          name: string
          school_id: string
        }
        Insert: {
          code?: string | null
          id?: string
          is_active?: boolean
          name: string
          school_id: string
        }
        Update: {
          code?: string | null
          id?: string
          is_active?: boolean
          name?: string
          school_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "subjects_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      teachers: {
        Row: {
          created_at: string
          full_name: string
          hired_on: string | null
          id: string
          is_active: boolean
          notes: string | null
          phone: string | null
          qualification: string | null
          school_id: string
        }
        Insert: {
          created_at?: string
          full_name: string
          hired_on?: string | null
          id?: string
          is_active?: boolean
          notes?: string | null
          phone?: string | null
          qualification?: string | null
          school_id: string
        }
        Update: {
          created_at?: string
          full_name?: string
          hired_on?: string | null
          id?: string
          is_active?: boolean
          notes?: string | null
          phone?: string | null
          qualification?: string | null
          school_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "teachers_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      teaching_assignments: {
        Row: {
          academic_year_id: string
          id: string
          section_id: string
          subject_id: string
          teacher_id: string
          weekly_periods: number | null
        }
        Insert: {
          academic_year_id: string
          id?: string
          section_id: string
          subject_id: string
          teacher_id: string
          weekly_periods?: number | null
        }
        Update: {
          academic_year_id?: string
          id?: string
          section_id?: string
          subject_id?: string
          teacher_id?: string
          weekly_periods?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "teaching_assignments_academic_year_id_fkey"
            columns: ["academic_year_id"]
            isOneToOne: false
            referencedRelation: "academic_years"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "teaching_assignments_section_id_fkey"
            columns: ["section_id"]
            isOneToOne: false
            referencedRelation: "sections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "teaching_assignments_subject_id_fkey"
            columns: ["subject_id"]
            isOneToOne: false
            referencedRelation: "subjects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "teaching_assignments_teacher_id_fkey"
            columns: ["teacher_id"]
            isOneToOne: false
            referencedRelation: "teachers"
            referencedColumns: ["id"]
          },
        ]
      }
      timetable_entries: {
        Row: {
          academic_year_id: string
          id: string
          period_id: string
          room: string | null
          section_id: string
          subject_id: string
          teacher_id: string
          weekday: number
        }
        Insert: {
          academic_year_id: string
          id?: string
          period_id: string
          room?: string | null
          section_id: string
          subject_id: string
          teacher_id: string
          weekday: number
        }
        Update: {
          academic_year_id?: string
          id?: string
          period_id?: string
          room?: string | null
          section_id?: string
          subject_id?: string
          teacher_id?: string
          weekday?: number
        }
        Relationships: [
          {
            foreignKeyName: "timetable_entries_academic_year_id_fkey"
            columns: ["academic_year_id"]
            isOneToOne: false
            referencedRelation: "academic_years"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "timetable_entries_period_id_fkey"
            columns: ["period_id"]
            isOneToOne: false
            referencedRelation: "periods"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "timetable_entries_section_id_fkey"
            columns: ["section_id"]
            isOneToOne: false
            referencedRelation: "sections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "timetable_entries_subject_id_fkey"
            columns: ["subject_id"]
            isOneToOne: false
            referencedRelation: "subjects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "timetable_entries_teacher_id_fkey"
            columns: ["teacher_id"]
            isOneToOne: false
            referencedRelation: "teachers"
            referencedColumns: ["id"]
          },
        ]
      }
      tracks: {
        Row: {
          grade_id: string
          id: string
          name: string
        }
        Insert: {
          grade_id: string
          id?: string
          name: string
        }
        Update: {
          grade_id?: string
          id?: string
          name?: string
        }
        Relationships: [
          {
            foreignKeyName: "tracks_grade_id_fkey"
            columns: ["grade_id"]
            isOneToOne: false
            referencedRelation: "grades"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          created_at: string
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
      fee_types: {
        Row: {
          created_at: string
          id: string
          is_active: boolean
          name: string
          school_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_active?: boolean
          name: string
          school_id: string
        }
        Update: {
          created_at?: string
          id?: string
          is_active?: boolean
          name?: string
          school_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "fee_types_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      fee_structures: {
        Row: {
          academic_year_id: string
          amount: number
          created_at: string
          description: string | null
          due_date: string | null
          fee_type_id: string
          grade_id: string
          id: string
          track_id: string | null
        }
        Insert: {
          academic_year_id: string
          amount: number
          created_at?: string
          description?: string | null
          due_date?: string | null
          fee_type_id: string
          grade_id: string
          id?: string
          track_id?: string | null
        }
        Update: {
          academic_year_id?: string
          amount?: number
          created_at?: string
          description?: string | null
          due_date?: string | null
          fee_type_id?: string
          grade_id?: string
          id?: string
          track_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fee_structures_academic_year_id_fkey"
            columns: ["academic_year_id"]
            isOneToOne: false
            referencedRelation: "academic_years"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fee_structures_fee_type_id_fkey"
            columns: ["fee_type_id"]
            isOneToOne: false
            referencedRelation: "fee_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fee_structures_grade_id_fkey"
            columns: ["grade_id"]
            isOneToOne: false
            referencedRelation: "grades"
            referencedColumns: ["id"]
          },
        ]
      }
      student_fee_discounts: {
        Row: {
          academic_year_id: string
          amount: number
          approved_by: string | null
          created_at: string
          discount_type: string
          fee_type_id: string
          id: string
          reason: string
          student_id: string
        }
        Insert: {
          academic_year_id: string
          amount: number
          approved_by?: string | null
          created_at?: string
          discount_type: string
          fee_type_id: string
          id?: string
          reason: string
          student_id: string
        }
        Update: {
          academic_year_id?: string
          amount?: number
          approved_by?: string | null
          created_at?: string
          discount_type?: string
          fee_type_id?: string
          id?: string
          reason?: string
          student_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "student_fee_discounts_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "students"
            referencedColumns: ["id"]
          },
        ]
      }
      student_payments: {
        Row: {
          academic_year_id: string
          amount: number
          created_at: string
          fee_type_id: string
          id: string
          notes: string | null
          payment_method: string
          receipt_number: string
          recorded_by: string | null
          student_id: string
        }
        Insert: {
          academic_year_id: string
          amount: number
          created_at?: string
          fee_type_id: string
          id?: string
          notes?: string | null
          payment_method?: string
          receipt_number: string
          recorded_by?: string | null
          student_id: string
        }
        Update: {
          academic_year_id?: string
          amount?: number
          created_at?: string
          fee_type_id?: string
          id?: string
          notes?: string | null
          payment_method?: string
          receipt_number?: string
          recorded_by?: string | null
          student_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "student_payments_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "students"
            referencedColumns: ["id"]
          },
        ]
      }
      guardians: {
        Row: {
          address: string | null
          created_at: string
          email: string | null
          full_name: string
          id: string
          national_id: string | null
          phone: string
          school_id: string
          user_id: string | null
        }
        Insert: {
          address?: string | null
          created_at?: string
          email?: string | null
          full_name: string
          id?: string
          national_id?: string | null
          phone: string
          school_id: string
          user_id?: string | null
        }
        Update: {
          address?: string | null
          created_at?: string
          email?: string | null
          full_name?: string
          id?: string
          national_id?: string | null
          phone?: string
          school_id?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "guardians_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      guardian_students: {
        Row: {
          can_view_fees: boolean
          created_at: string
          guardian_id: string
          id: string
          is_primary: boolean
          receives_notifications: boolean
          relation: string
          student_id: string
          verified_by: string | null
        }
        Insert: {
          can_view_fees?: boolean
          created_at?: string
          guardian_id: string
          id?: string
          is_primary?: boolean
          receives_notifications?: boolean
          relation?: string
          student_id: string
          verified_by?: string | null
        }
        Update: {
          can_view_fees?: boolean
          created_at?: string
          guardian_id?: string
          id?: string
          is_primary?: boolean
          receives_notifications?: boolean
          relation?: string
          student_id?: string
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "guardian_students_guardian_id_fkey"
            columns: ["guardian_id"]
            isOneToOne: false
            referencedRelation: "guardians"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "guardian_students_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "students"
            referencedColumns: ["id"]
          },
        ]
      }
      assessment_categories: {
        Row: {
          created_at: string
          default_max_score: number
          id: string
          is_active: boolean
          name: string
          school_id: string
          weight: number
        }
        Insert: {
          created_at?: string
          default_max_score?: number
          id?: string
          is_active?: boolean
          name: string
          school_id: string
          weight?: number
        }
        Update: {
          created_at?: string
          default_max_score?: number
          id?: string
          is_active?: boolean
          name?: string
          school_id?: string
          weight?: number
        }
        Relationships: [
          {
            foreignKeyName: "assessment_categories_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
      assessments: {
        Row: {
          academic_year_id: string
          approved_by: string | null
          created_at: string
          created_by: string | null
          id: string
          max_score: number
          pass_score: number
          section_id: string
          status: string
          subject_id: string
          term: string
          title: string
          updated_at: string
        }
        Insert: {
          academic_year_id: string
          approved_by?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          max_score?: number
          pass_score?: number
          section_id: string
          status?: string
          subject_id: string
          term?: string
          title: string
          updated_at?: string
        }
        Update: {
          academic_year_id?: string
          approved_by?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          max_score?: number
          pass_score?: number
          section_id?: string
          status?: string
          subject_id?: string
          term?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "assessments_academic_year_id_fkey"
            columns: ["academic_year_id"]
            isOneToOne: false
            referencedRelation: "academic_years"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assessments_section_id_fkey"
            columns: ["section_id"]
            isOneToOne: false
            referencedRelation: "sections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assessments_subject_id_fkey"
            columns: ["subject_id"]
            isOneToOne: false
            referencedRelation: "subjects"
            referencedColumns: ["id"]
          },
        ]
      }
      student_grades: {
        Row: {
          absence_reason: string | null
          assessment_id: string
          id: string
          is_absent: boolean
          notes: string | null
          score: number | null
          student_id: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          absence_reason?: string | null
          assessment_id: string
          id?: string
          is_absent?: boolean
          notes?: string | null
          score?: number | null
          student_id: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          absence_reason?: string | null
          assessment_id?: string
          id?: string
          is_absent?: boolean
          notes?: string | null
          score?: number | null
          student_id?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "student_grades_assessment_id_fkey"
            columns: ["assessment_id"]
            isOneToOne: false
            referencedRelation: "assessments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "student_grades_student_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "students"
            referencedColumns: ["id"]
          },
        ]
      }
      school_events: {
        Row: {
          academic_year_id: string | null
          created_at: string
          created_by: string | null
          description: string | null
          ends_on: string | null
          event_type: "term_date" | "exam" | "holiday" | "meeting" | "event" | "result"
          id: string
          is_published: boolean
          school_id: string
          starts_on: string
          target_audience: "all" | "students" | "teachers" | "parents" | "staff_only"
          title: string
          updated_at: string
        }
        Insert: {
          academic_year_id?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          ends_on?: string | null
          event_type: "term_date" | "exam" | "holiday" | "meeting" | "event" | "result"
          id?: string
          is_published?: boolean
          school_id: string
          starts_on: string
          target_audience?: "all" | "students" | "teachers" | "parents" | "staff_only"
          title: string
          updated_at?: string
        }
        Update: {
          academic_year_id?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          ends_on?: string | null
          event_type?: "term_date" | "exam" | "holiday" | "meeting" | "event" | "result"
          id?: string
          is_published?: boolean
          school_id?: string
          starts_on?: string
          target_audience?: "all" | "students" | "teachers" | "parents" | "staff_only"
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "school_events_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "school_events_academic_year_id_fkey"
            columns: ["academic_year_id"]
            isOneToOne: false
            referencedRelation: "academic_years"
            referencedColumns: ["id"]
          },
        ]
      }
      announcements: {
        Row: {
          body: string
          created_at: string
          created_by: string | null
          expires_at: string | null
          id: string
          is_published: boolean
          priority: "normal" | "important" | "urgent"
          published_at: string
          school_id: string
          target_audience: "all" | "students" | "teachers" | "parents" | "staff_only"
          title: string
        }
        Insert: {
          body: string
          created_at?: string
          created_by?: string | null
          expires_at?: string | null
          id?: string
          is_published?: boolean
          priority?: "normal" | "important" | "urgent"
          published_at?: string
          school_id: string
          target_audience?: "all" | "students" | "teachers" | "parents" | "staff_only"
          title: string
        }
        Update: {
          body?: string
          created_at?: string
          created_by?: string | null
          expires_at?: string | null
          id?: string
          is_published?: boolean
          priority?: "normal" | "important" | "urgent"
          published_at?: string
          school_id?: string
          target_audience?: "all" | "students" | "teachers" | "parents" | "staff_only"
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "announcements_school_id_fkey"
            columns: ["school_id"]
            isOneToOne: false
            referencedRelation: "schools"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      can_manage: { Args: { _user_id: string }; Returns: boolean }
      change_student_status: {
        Args: {
          _reason: string
          _status: Database["public"]["Enums"]["student_status"]
          _student: string
        }
        Returns: undefined
      }
      create_student_with_enrollment: {
        Args: {
          _academic_year: string
          _enrollment_type: Database["public"]["Enums"]["enrollment_type"]
          _section: string
          _student: Json
        }
        Returns: string
      }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_staff: { Args: { _user_id: string }; Returns: boolean }
      save_daily_attendance: {
        Args: { _absences: Json; _date: string; _section: string }
        Returns: string
      }
    }
    Enums: {
      app_role: "owner" | "principal" | "supervisor"
      enrollment_status:
        | "active"
        | "promoted"
        | "repeated"
        | "transferred_out"
        | "withdrawn"
        | "graduated"
      enrollment_type: "new" | "transfer_in" | "continuing"
      student_status:
        | "active"
        | "transferred_out"
        | "withdrawn"
        | "graduated"
        | "suspended"
      timetable_status: "draft" | "approved"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["owner", "principal", "supervisor"],
      enrollment_status: [
        "active",
        "promoted",
        "repeated",
        "transferred_out",
        "withdrawn",
        "graduated",
      ],
      enrollment_type: ["new", "transfer_in", "continuing"],
      student_status: [
        "active",
        "transferred_out",
        "withdrawn",
        "graduated",
        "suspended",
      ],
      timetable_status: ["draft", "approved"],
    },
  },
} as const
