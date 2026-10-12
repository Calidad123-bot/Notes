alter table public.notes
    add column if not exists tags jsonb not null default '[]'::jsonb,
    add column if not exists favorite boolean not null default false,
    add column if not exists created_at timestamptz not null default now();

create unique index if not exists notes_user_id_id_uidx
    on public.notes (user_id, id);
