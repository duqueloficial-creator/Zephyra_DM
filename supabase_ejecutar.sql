-- ============================================================
-- PARTE A: ARREGLO DE REGISTRO / LOGIN (@ con cualquier nombre)
-- ============================================================
-- Agrega la columna donde se guarda la versión "limpia" del @
-- (sin tildes/espacios) que se usa por dentro para el login.
alter table "profiles" add column if not exists "auth_slug" text;

-- Evita duplicados de @ a nivel de base de datos (sin importar mayúsculas/tildes de más)
create unique index if not exists profiles_handle_unique_idx on "profiles" (lower(handle));

-- Evita que dos @ distintos (ej: "María" y "maria") generen el mismo login interno
create unique index if not exists profiles_auth_slug_unique_idx on "profiles" (auth_slug);

-- ============================================================
-- PARTE B: FASE 3 - RED SOCIAL (posts, seguidores, notificaciones)
-- ============================================================
-- Pegá y ejecutá todo esto en el SQL Editor de Supabase.
-- No borra nada de lo que ya tenés (Fases 1 y 2 siguen intactas).
-- ============================================================

create table if not exists "posts" (
  id bigint generated always as identity primary key,
  owner_id uuid references auth.users(id) on delete cascade,
  media_url text not null,
  media_type text not null, -- image | video
  caption text default '',
  is_public boolean default true,
  created_at timestamptz default now()
);
alter table "posts" enable row level security;
create policy "ver posts publicos o propios" on "posts" for select using (is_public = true or owner_id = auth.uid());
create policy "crear posts propios" on "posts" for insert with check (owner_id = auth.uid());
create policy "editar posts propios" on "posts" for update using (owner_id = auth.uid());
create policy "borrar posts propios" on "posts" for delete using (owner_id = auth.uid());

create table if not exists "post_likes" (
  post_id bigint references "posts"(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (post_id, user_id)
);
alter table "post_likes" enable row level security;
create policy "ver likes" on "post_likes" for select using (true);
create policy "dar like" on "post_likes" for insert with check (auth.uid() = user_id);
create policy "quitar like" on "post_likes" for delete using (auth.uid() = user_id);

create table if not exists "post_saves" (
  post_id bigint references "posts"(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (post_id, user_id)
);
alter table "post_saves" enable row level security;
create policy "ver mis guardados" on "post_saves" for select using (auth.uid() = user_id);
create policy "guardar post" on "post_saves" for insert with check (auth.uid() = user_id);
create policy "quitar guardado" on "post_saves" for delete using (auth.uid() = user_id);

create table if not exists "post_shares" (
  id bigint generated always as identity primary key,
  post_id bigint references "posts"(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);
alter table "post_shares" enable row level security;
create policy "ver shares" on "post_shares" for select using (true);
create policy "compartir post" on "post_shares" for insert with check (auth.uid() = user_id);

create table if not exists "post_comments" (
  id bigint generated always as identity primary key,
  post_id bigint references "posts"(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  content text not null,
  pinned boolean default false,
  created_at timestamptz default now()
);
alter table "post_comments" enable row level security;
create policy "ver comentarios" on "post_comments" for select using (true);
create policy "comentar" on "post_comments" for insert with check (auth.uid() = user_id);
create policy "borrar mi comentario" on "post_comments" for delete using (auth.uid() = user_id);
create policy "actualizar comentario (pin del dueño del post)" on "post_comments" for update using (true);

create table if not exists "comment_likes" (
  comment_id bigint references "post_comments"(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (comment_id, user_id)
);
alter table "comment_likes" enable row level security;
create policy "ver comment likes" on "comment_likes" for select using (true);
create policy "dar like a comentario" on "comment_likes" for insert with check (auth.uid() = user_id);
create policy "quitar like a comentario" on "comment_likes" for delete using (auth.uid() = user_id);

create table if not exists "follows" (
  follower_id uuid references auth.users(id) on delete cascade,
  following_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (follower_id, following_id)
);
alter table "follows" enable row level security;
create policy "ver follows" on "follows" for select using (true);
create policy "seguir" on "follows" for insert with check (auth.uid() = follower_id);
create policy "dejar de seguir" on "follows" for delete using (auth.uid() = follower_id);

create table if not exists "notifications" (
  id bigint generated always as identity primary key,
  recipient_id uuid references auth.users(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete cascade,
  type text not null, -- follow | like | comment | mention
  post_id bigint,
  comment_id bigint,
  created_at timestamptz default now(),
  read boolean default false
);
alter table "notifications" enable row level security;
create policy "ver mis notificaciones" on "notifications" for select using (auth.uid() = recipient_id);
create policy "crear notificacion" on "notifications" for insert with check (true);
create policy "marcar leida" on "notifications" for update using (auth.uid() = recipient_id);

create table if not exists "highlights" (
  id bigint generated always as identity primary key,
  owner_id uuid references auth.users(id) on delete cascade,
  title text not null,
  cover_url text,
  created_at timestamptz default now()
);
alter table "highlights" enable row level security;
create policy "ver destacados" on "highlights" for select using (true);
create policy "crear destacado propio" on "highlights" for insert with check (auth.uid() = owner_id);
create policy "borrar destacado propio" on "highlights" for delete using (auth.uid() = owner_id);

create table if not exists "highlight_items" (
  highlight_id bigint references "highlights"(id) on delete cascade,
  post_id bigint references "posts"(id) on delete cascade,
  position int default 0,
  primary key (highlight_id, post_id)
);
alter table "highlight_items" enable row level security;
create policy "ver items destacados" on "highlight_items" for select using (true);
create policy "agregar item destacado" on "highlight_items" for insert with check (
  exists (select 1 from "highlights" h where h.id = highlight_id and h.owner_id = auth.uid())
);
create policy "quitar item destacado" on "highlight_items" for delete using (
  exists (select 1 from "highlights" h where h.id = highlight_id and h.owner_id = auth.uid())
);

create table if not exists "profile_views" (
  viewer_id uuid references auth.users(id) on delete cascade,
  viewed_id uuid references auth.users(id) on delete cascade,
  viewed_at timestamptz default now(),
  primary key (viewer_id, viewed_id)
);
alter table "profile_views" enable row level security;
create policy "ver quien vio mi perfil" on "profile_views" for select using (auth.uid() = viewed_id or auth.uid() = viewer_id);
create policy "registrar visita" on "profile_views" for insert with check (auth.uid() = viewer_id);
create policy "actualizar visita" on "profile_views" for update using (auth.uid() = viewer_id);

-- Bucket para posts y destacados
insert into storage.buckets (id, name, public) values ('posts','posts', true) on conflict (id) do nothing;
create policy "posts select publico" on storage.objects for select using (bucket_id = 'posts');
create policy "posts insert propio" on storage.objects for insert
  with check (bucket_id = 'posts' and auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================================
-- Recomendado: Database -> Replication -> activá también
-- post_likes, post_comments, notifications y follows.
-- ============================================================
