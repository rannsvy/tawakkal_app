-- Guard profile creation so it only happens after email verification.
-- This prevents profile rows for users who have not completed signup OTP.

create or replace function public.tawakkal_enforce_verified_profile_insert()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if exists (
    select 1
    from auth.users u
    where u.id = new.user_id
      and u.email_confirmed_at is not null
  ) then
    return new;
  end if;

  raise exception
    'Profile can only be created after email verification.'
    using errcode = '23514';
end;
$$;

drop trigger if exists tawakkal_profiles_require_verified_email on public.profiles;
create trigger tawakkal_profiles_require_verified_email
before insert on public.profiles
for each row
execute function public.tawakkal_enforce_verified_profile_insert();

create or replace function public.tawakkal_create_profile_after_verification()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if old.email_confirmed_at is not null or new.email_confirmed_at is null then
    return new;
  end if;

  insert into public.profiles (user_id, display_name)
  values (
    new.id,
    nullif(
      trim(coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1))),
      ''
    )
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create or replace function public.tawakkal_create_profile_on_confirmed_insert()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if new.email_confirmed_at is null then
    return new;
  end if;

  insert into public.profiles (user_id, display_name)
  values (
    new.id,
    nullif(
      trim(coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1))),
      ''
    )
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists tawakkal_create_profile_after_verification on auth.users;
create trigger tawakkal_create_profile_after_verification
after update of email_confirmed_at on auth.users
for each row
execute function public.tawakkal_create_profile_after_verification();

drop trigger if exists tawakkal_create_profile_on_confirmed_insert on auth.users;
create trigger tawakkal_create_profile_on_confirmed_insert
after insert on auth.users
for each row
execute function public.tawakkal_create_profile_on_confirmed_insert();

-- Backfill for users who are already verified but missing profile rows.
insert into public.profiles (user_id, display_name)
select
  u.id,
  nullif(
    trim(coalesce(u.raw_user_meta_data ->> 'full_name', split_part(u.email, '@', 1))),
    ''
  )
from auth.users u
where u.email_confirmed_at is not null
on conflict (user_id) do nothing;
