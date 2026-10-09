-- Pegar todo en Supabase → SQL Editor → Run. Se corre una sola vez.

-- Quiénes pueden entrar: solo estos mails.
-- Para sumar a alguien después: insert into socios (email) values ('mail@socio.com');
create table socios (email text primary key);
insert into socios (email) values ('romnmarti@gmail.com'), ('brisasosa335@gmail.com');
alter table socios enable row level security; -- sin políticas: nadie la lee desde la web

create function es_socio() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from socios where email = auth.jwt() ->> 'email')
$$;

create table leads (
  id uuid primary key default gen_random_uuid(),
  cliente text not null check (length(cliente) <= 80),
  contacto text,
  necesidad text,
  paquete text,
  monto numeric not null default 0 check (monto >= 0),
  plazo text,
  origen text,
  material text,
  etapa text not null default 'lead'
    check (etapa in ('lead','propuesta','desarrollo','entregado','pagado')),
  creado timestamptz not null default now()
);

-- Textos editables (paquetes, flujo, acuerdo)
create table contenido (
  id text primary key,
  html text not null,
  actualizado timestamptz not null default now()
);

alter table leads enable row level security;
alter table contenido enable row level security;
create policy socios_leads on leads for all to authenticated using (es_socio()) with check (es_socio());
create policy socios_contenido on contenido for all to authenticated using (es_socio()) with check (es_socio());

-- Cambios en vivo entre los dos
alter publication supabase_realtime add table leads, contenido;

-- Sitios publicados (agregado después: si ya corriste lo de arriba, corré solo desde acá)
create table sitios (
  id uuid primary key default gen_random_uuid(),
  nombre text not null check (length(nombre) <= 80),
  url text not null check (url ~* '^https?://' and length(url) <= 300),
  cliente text,
  tipo text,
  creado timestamptz not null default now()
);
alter table sitios enable row level security;
create policy socios_sitios on sitios for all to authenticated using (es_socio()) with check (es_socio());
alter publication supabase_realtime add table sitios;
