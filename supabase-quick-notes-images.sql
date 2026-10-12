alter table public.notes
    add column if not exists images jsonb not null default '[]'::jsonb;

alter table public.notes
    add column if not exists tags jsonb not null default '[]'::jsonb,
    add column if not exists favorite boolean not null default false,
    add column if not exists created_at timestamptz not null default now();

create unique index if not exists notes_user_id_id_uidx
    on public.notes (user_id, id);

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