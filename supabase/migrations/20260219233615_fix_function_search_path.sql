-- Fix mutable search_path security advisory on handle_new_user
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id) values (new.id);
  return new;
end;
$$ language plpgsql security definer set search_path = public;
