-- ============================================================
-- SCRIPT COMPLETO PARA EL CHAT (grupal + privados + perfiles)
-- ============================================================
-- Cómo usar:
-- 1. Entrá a supabase.com -> tu proyecto
-- 2. Menú izquierdo -> "SQL Editor" -> "+ New query"
-- 3. Pegá TODO este contenido
-- 4. Apretá el botón "Run" (o Ctrl+Enter)
--
-- ATENCIÓN: esto borra la tabla DUQUEL anterior y sus mensajes
-- de prueba, y crea todo de nuevo limpio.
-- ============================================================

-- Limpieza de tablas anteriores (si existen)
drop table if exists "DUQUEL";
drop table if exists "profiles";
drop table if exists "typing_status";

-- Tabla principal de mensajes (grupales y privados)
create table "DUQUEL" (
  id bigint generated always as identity primary key,
  created_at timestamptz default now(),
  sender text not null,
  recipient text,              -- null = mensaje grupal, texto = mensaje privado a ese usuario
  content text not null,
  reply_to_sender text,
  reply_to_content text
);

-- Tabla de perfiles (foto de perfil por nombre de usuario)
create table "profiles" (
  username text primary key,
  avatar_url text,
  updated_at timestamptz default now()
);

-- Tabla de estado "escribiendo..."
create table "typing_status" (
  username text primary key,
  chat_target text not null,   -- 'GROUP' o el nombre del usuario al que le está escribiendo
  updated_at timestamptz default now()
);

-- Seguridad de filas (abierta, ya que no hay login real)
alter table "DUQUEL" enable row level security;
alter table "profiles" enable row level security;
alter table "typing_status" enable row level security;

create policy "permitir todo duquel" on "DUQUEL" for all using (true) with check (true);
create policy "permitir todo profiles" on "profiles" for all using (true) with check (true);
create policy "permitir todo typing" on "typing_status" for all using (true) with check (true);

-- Bucket de almacenamiento para las fotos de perfil
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "avatares select publico"
on storage.objects for select
using (bucket_id = 'avatars');

create policy "avatares insert publico"
on storage.objects for insert
with check (bucket_id = 'avatars');

create policy "avatares update publico"
on storage.objects for update
using (bucket_id = 'avatars');

-- ============================================================
-- PASO EXTRA RECOMENDADO (no es SQL, es en la interfaz):
-- Menú izquierdo -> Database -> Replication
-- Activá el switch de las tablas: DUQUEL, typing_status
-- (esto hace que los mensajes y el "escribiendo..." sean
-- instantáneos; si no lo activás, igual funciona por polling
-- cada pocos segundos)
-- ============================================================
