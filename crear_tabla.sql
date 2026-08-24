-- ============================================
-- SCRIPT PARA CREAR LA TABLA DEL CHAT EN SUPABASE
-- ============================================
-- Cómo usar:
-- 1. Entrá a supabase.com -> tu proyecto
-- 2. Menú izquierdo -> "SQL Editor" -> "+ New query"
-- 3. Pegá TODO este contenido
-- 4. Apretá el botón "Run" (o Ctrl+Enter)
-- ============================================

create table "DUQUEL" (
  id bigint generated always as identity primary key,
  created_at timestamptz default now(),
  sender text,
  content text,
  reply_to_sender text,
  reply_to_content text
);

alter table "DUQUEL" enable row level security;

create policy "permitir todo" on "DUQUEL"
for all using (true) with check (true);
