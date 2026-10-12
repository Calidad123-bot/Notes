create table if not exists public.notes (
    id text not null,
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null default 'Untitled',
    body text not null default '',
    images jsonb not null default '[]'::jsonb,
    tags jsonb not null default '[]'::jsonb,
    favorite boolean not null default false,
    date text not null default '',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted boolean not null default false
);

alter table public.notes
    add column if not exists images jsonb not null default '[]'::jsonb,
    add column if not exists tags jsonb not null default '[]'::jsonb,
    add column if not exists favorite boolean not null default false,
    add column if not exists created_at timestamptz not null default now(),
    add column if not exists deleted boolean not null default false;

create unique index if not exists notes_user_id_id_uidx
    on public.notes (user_id, id);

alter table public.notes enable row level security;

grant select, insert, update, delete on public.notes to authenticated;

drop policy if exists "Users can read their own notes" on public.notes;
create policy "Users can read their own notes"
    on public.notes for select
    to authenticated
    using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own notes" on public.notes;
create policy "Users can create their own notes"
    on public.notes for insert
    to authenticated
    with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own notes" on public.notes;
create policy "Users can update their own notes"
    on public.notes for update
    to authenticated
    using ((select auth.uid()) = user_id)
    with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own notes" on public.notes;
create policy "Users can delete their own notes"
    on public.notes for delete
    to authenticated
    using ((select auth.uid()) = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'quick-note-images',
    'quick-note-images',
    false,
    10485760,
    array['image/jpeg', 'image/png', 'image/gif', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Quick notes images are readable by owner" on storage.objects;
create policy "Quick notes images are readable by owner"
    on storage.objects for select
    to authenticated
    using (
        bucket_id = 'quick-note-images'
        and (storage.foldername(name))[1] = (select auth.uid()::text)
    );

drop policy if exists "Quick notes images can be uploaded by owner" on storage.objects;
create policy "Quick notes images can be uploaded by owner"
    on storage.objects for insert
    to authenticated
    with check (
        bucket_id = 'quick-note-images'
        and (storage.foldername(name))[1] = (select auth.uid()::text)
    );

drop policy if exists "Quick notes images can be deleted by owner" on storage.objects;
create policy "Quick notes images can be deleted by owner"
    on storage.objects for delete
    to authenticated
    using (
        bucket_id = 'quick-note-images'
        and (storage.foldername(name))[1] = (select auth.uid()::text)
    );

create table if not exists public.email_templates (
    id text not null,
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null default 'Untitled template',
    category text not null default 'General',
    subject text not null default '',
    body text not null default '',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted boolean not null default false
);

alter table public.email_templates
    add column if not exists created_at timestamptz not null default now(),
    add column if not exists updated_at timestamptz not null default now(),
    add column if not exists deleted boolean not null default false;

create unique index if not exists email_templates_user_id_id_uidx
    on public.email_templates (user_id, id);

alter table public.email_templates enable row level security;

grant select, insert, update, delete on public.email_templates to authenticated;

drop policy if exists "Users can read their own email templates" on public.email_templates;
create policy "Users can read their own email templates"
    on public.email_templates for select
    to authenticated
    using ((select auth.uid()) = user_id);

drop policy if exists "Users can create their own email templates" on public.email_templates;
create policy "Users can create their own email templates"
    on public.email_templates for insert
    to authenticated
    with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own email templates" on public.email_templates;
create policy "Users can update their own email templates"
    on public.email_templates for update
    to authenticated
    using ((select auth.uid()) = user_id)
    with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own email templates" on public.email_templates;
create policy "Users can delete their own email templates"
    on public.email_templates for delete
    to authenticated
    using ((select auth.uid()) = user_id);