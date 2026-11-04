-- Run once in a NEW Supabase project's SQL Editor.
begin;
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 name text not null check (length(trim(name)) between 1 and 80),
 email text not null check (length(email) between 3 and 254),
 phone text not null default '' check(length(phone)<=40),
 created_at timestamptz not null default now()
);
create table public.issues (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null default auth.uid() references public.profiles(id),
 title text not null check(length(trim(title)) between 1 and 120),
 description text not null check(length(trim(description)) between 1 and 4000),
 status text not null default 'open' check(status in ('open','closed')),
 created_at timestamptz not null default now()
);
create table public.tasks (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null default auth.uid() references public.profiles(id),
 assignee_id uuid not null references public.profiles(id),
 title text not null check(length(trim(title)) between 1 and 120),
 description text not null check(length(trim(description)) between 1 and 4000),
 status text not null default 'todo' check(status in ('todo','in_progress','blocked','done')),
 due_date date,
 created_at timestamptz not null default now()
);
create table public.comments (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null default auth.uid() references public.profiles(id),
 task_id uuid not null references public.tasks(id) on delete cascade,
 body text not null check(length(trim(body)) between 1 and 2000),
 created_at timestamptz not null default now()
);
create index tasks_assignee on public.tasks(assignee_id);
create index comments_task on public.comments(task_id);
create index issues_owner on public.issues(owner_id);
create index tasks_owner on public.tasks(owner_id);
create index comments_owner on public.comments(owner_id);

create function public.new_member() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.profiles(id,name,email) values(new.id,coalesce(nullif(left(trim(new.raw_user_meta_data->>'name'),80),''),'Community member'),new.email);
 return new;
end;
$$;
revoke all on function public.new_member() from public;
create trigger on_member_created after insert on auth.users for each row execute function public.new_member();

-- Ownership, IDs, timestamps, and comment parent tasks are immutable.
create function public.protect_identity() returns trigger language plpgsql set search_path='' as $$
begin
 if new.id is distinct from old.id or new.created_at is distinct from old.created_at then raise exception 'Record identity is immutable'; end if;
 if tg_table_name <> 'profiles' then
  if new.owner_id is distinct from old.owner_id then raise exception 'Ownership cannot be transferred'; end if;
 end if;
 if tg_table_name = 'comments' then
  if new.task_id is distinct from old.task_id then raise exception 'Comment task cannot be changed'; end if;
 end if;
 return new;
end;
$$;
revoke all on function public.protect_identity() from public;
do $$ declare t text; owner_column text; begin
 foreach t in array array['profiles','issues','tasks','comments'] loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from anon, authenticated',t);
  execute format('grant select, update on public.%I to authenticated',t);
  execute format('create policy community_read on public.%I for select to authenticated using (true)',t);
  owner_column := case when t='profiles' then 'id' else 'owner_id' end;
  execute format('create policy owner_update on public.%I for update to authenticated using ((select auth.uid()) = %I) with check ((select auth.uid()) = %I)',t,owner_column,owner_column);
  if t <> 'profiles' then
   execute format('grant insert, delete on public.%I to authenticated',t);
   execute format('create policy owner_insert on public.%I for insert to authenticated with check ((select auth.uid()) = owner_id)',t);
   execute format('create policy owner_delete on public.%I for delete to authenticated using ((select auth.uid()) = owner_id)',t);
  end if;
  execute format('create trigger protect_identity before update on public.%I for each row execute function public.protect_identity()',t);
 end loop;
end $$;
commit;
