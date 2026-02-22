drop extension if exists "pg_net";

create extension if not exists "postgis" with schema "public";


  create table "public"."chat_room" (
    "id" uuid not null default gen_random_uuid(),
    "created_at" timestamp with time zone not null default now(),
    "name" character varying not null,
    "is_public" boolean not null
      );


alter table "public"."chat_room" enable row level security;


  create table "public"."chats" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "item_id" uuid,
    "finder_id" uuid,
    "owner_id" uuid,
    "status" text default 'active'::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."chats" enable row level security;


  create table "public"."items" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "user_id" uuid,
    "type" text not null,
    "title" text not null,
    "description" text,
    "category" text,
    "location_lat" numeric(10,8),
    "location_lng" numeric(11,8),
    "location_name" text,
    "current_location_lat" numeric(10,8),
    "current_location_lng" numeric(11,8),
    "current_location_name" text,
    "image_url" text,
    "date_found" timestamp with time zone,
    "date_lost" timestamp with time zone,
    "status" text default 'active'::text,
    "expires_at" timestamp with time zone,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "location_point" public.geography(Point,4326)
      );


alter table "public"."items" enable row level security;


  create table "public"."notifications" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "user_id" uuid,
    "title" text not null,
    "body" text not null,
    "data" jsonb,
    "is_read" boolean default false,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."notifications" enable row level security;


  create table "public"."users" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "username" text not null,
    "email" text not null,
    "password_hash" text not null,
    "notification_token" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."users" enable row level security;

CREATE UNIQUE INDEX chat_room_pkey ON public.chat_room USING btree (id);

CREATE UNIQUE INDEX chats_item_id_finder_id_owner_id_key ON public.chats USING btree (item_id, finder_id, owner_id);

CREATE UNIQUE INDEX chats_pkey ON public.chats USING btree (id);

CREATE UNIQUE INDEX items_pkey ON public.items USING btree (id);

CREATE UNIQUE INDEX notifications_pkey ON public.notifications USING btree (id);

CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email);

CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id);

CREATE UNIQUE INDEX users_username_key ON public.users USING btree (username);

alter table "public"."chat_room" add constraint "chat_room_pkey" PRIMARY KEY using index "chat_room_pkey";

alter table "public"."chats" add constraint "chats_pkey" PRIMARY KEY using index "chats_pkey";

alter table "public"."items" add constraint "items_pkey" PRIMARY KEY using index "items_pkey";

alter table "public"."notifications" add constraint "notifications_pkey" PRIMARY KEY using index "notifications_pkey";

alter table "public"."users" add constraint "users_pkey" PRIMARY KEY using index "users_pkey";

alter table "public"."chats" add constraint "chats_finder_id_fkey" FOREIGN KEY (finder_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."chats" validate constraint "chats_finder_id_fkey";

alter table "public"."chats" add constraint "chats_item_id_finder_id_owner_id_key" UNIQUE using index "chats_item_id_finder_id_owner_id_key";

alter table "public"."chats" add constraint "chats_item_id_fkey" FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE not valid;

alter table "public"."chats" validate constraint "chats_item_id_fkey";

alter table "public"."chats" add constraint "chats_owner_id_fkey" FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."chats" validate constraint "chats_owner_id_fkey";

alter table "public"."chats" add constraint "chats_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'closed'::text]))) not valid;

alter table "public"."chats" validate constraint "chats_status_check";

alter table "public"."items" add constraint "items_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'claimed'::text, 'expired'::text, 'deleted'::text]))) not valid;

alter table "public"."items" validate constraint "items_status_check";

alter table "public"."items" add constraint "items_type_check" CHECK ((type = ANY (ARRAY['lost'::text, 'found'::text]))) not valid;

alter table "public"."items" validate constraint "items_type_check";

alter table "public"."notifications" add constraint "notifications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."notifications" validate constraint "notifications_user_id_fkey";

alter table "public"."users" add constraint "users_email_key" UNIQUE using index "users_email_key";

alter table "public"."users" add constraint "users_username_key" UNIQUE using index "users_username_key";

create type "public"."geometry_dump" as ("path" integer[], "geom" public.geometry);

create type "public"."valid_detail" as ("valid" boolean, "reason" character varying, "location" public.geometry);

grant delete on table "public"."chat_room" to "anon";

grant insert on table "public"."chat_room" to "anon";

grant references on table "public"."chat_room" to "anon";

grant select on table "public"."chat_room" to "anon";

grant trigger on table "public"."chat_room" to "anon";

grant truncate on table "public"."chat_room" to "anon";

grant update on table "public"."chat_room" to "anon";

grant delete on table "public"."chat_room" to "authenticated";

grant insert on table "public"."chat_room" to "authenticated";

grant references on table "public"."chat_room" to "authenticated";

grant select on table "public"."chat_room" to "authenticated";

grant trigger on table "public"."chat_room" to "authenticated";

grant truncate on table "public"."chat_room" to "authenticated";

grant update on table "public"."chat_room" to "authenticated";

grant delete on table "public"."chat_room" to "service_role";

grant insert on table "public"."chat_room" to "service_role";

grant references on table "public"."chat_room" to "service_role";

grant select on table "public"."chat_room" to "service_role";

grant trigger on table "public"."chat_room" to "service_role";

grant truncate on table "public"."chat_room" to "service_role";

grant update on table "public"."chat_room" to "service_role";

grant delete on table "public"."chats" to "anon";

grant insert on table "public"."chats" to "anon";

grant references on table "public"."chats" to "anon";

grant select on table "public"."chats" to "anon";

grant trigger on table "public"."chats" to "anon";

grant truncate on table "public"."chats" to "anon";

grant update on table "public"."chats" to "anon";

grant delete on table "public"."chats" to "authenticated";

grant insert on table "public"."chats" to "authenticated";

grant references on table "public"."chats" to "authenticated";

grant select on table "public"."chats" to "authenticated";

grant trigger on table "public"."chats" to "authenticated";

grant truncate on table "public"."chats" to "authenticated";

grant update on table "public"."chats" to "authenticated";

grant delete on table "public"."chats" to "service_role";

grant insert on table "public"."chats" to "service_role";

grant references on table "public"."chats" to "service_role";

grant select on table "public"."chats" to "service_role";

grant trigger on table "public"."chats" to "service_role";

grant truncate on table "public"."chats" to "service_role";

grant update on table "public"."chats" to "service_role";

grant delete on table "public"."items" to "anon";

grant insert on table "public"."items" to "anon";

grant references on table "public"."items" to "anon";

grant select on table "public"."items" to "anon";

grant trigger on table "public"."items" to "anon";

grant truncate on table "public"."items" to "anon";

grant update on table "public"."items" to "anon";

grant delete on table "public"."items" to "authenticated";

grant insert on table "public"."items" to "authenticated";

grant references on table "public"."items" to "authenticated";

grant select on table "public"."items" to "authenticated";

grant trigger on table "public"."items" to "authenticated";

grant truncate on table "public"."items" to "authenticated";

grant update on table "public"."items" to "authenticated";

grant delete on table "public"."items" to "service_role";

grant insert on table "public"."items" to "service_role";

grant references on table "public"."items" to "service_role";

grant select on table "public"."items" to "service_role";

grant trigger on table "public"."items" to "service_role";

grant truncate on table "public"."items" to "service_role";

grant update on table "public"."items" to "service_role";

grant delete on table "public"."notifications" to "anon";

grant insert on table "public"."notifications" to "anon";

grant references on table "public"."notifications" to "anon";

grant select on table "public"."notifications" to "anon";

grant trigger on table "public"."notifications" to "anon";

grant truncate on table "public"."notifications" to "anon";

grant update on table "public"."notifications" to "anon";

grant delete on table "public"."notifications" to "authenticated";

grant insert on table "public"."notifications" to "authenticated";

grant references on table "public"."notifications" to "authenticated";

grant select on table "public"."notifications" to "authenticated";

grant trigger on table "public"."notifications" to "authenticated";

grant truncate on table "public"."notifications" to "authenticated";

grant update on table "public"."notifications" to "authenticated";

grant delete on table "public"."notifications" to "service_role";

grant insert on table "public"."notifications" to "service_role";

grant references on table "public"."notifications" to "service_role";

grant select on table "public"."notifications" to "service_role";

grant trigger on table "public"."notifications" to "service_role";

grant truncate on table "public"."notifications" to "service_role";

grant update on table "public"."notifications" to "service_role";

grant delete on table "public"."spatial_ref_sys" to "anon";

grant insert on table "public"."spatial_ref_sys" to "anon";

grant references on table "public"."spatial_ref_sys" to "anon";

grant select on table "public"."spatial_ref_sys" to "anon";

grant trigger on table "public"."spatial_ref_sys" to "anon";

grant truncate on table "public"."spatial_ref_sys" to "anon";

grant update on table "public"."spatial_ref_sys" to "anon";

grant delete on table "public"."spatial_ref_sys" to "authenticated";

grant insert on table "public"."spatial_ref_sys" to "authenticated";

grant references on table "public"."spatial_ref_sys" to "authenticated";

grant select on table "public"."spatial_ref_sys" to "authenticated";

grant trigger on table "public"."spatial_ref_sys" to "authenticated";

grant truncate on table "public"."spatial_ref_sys" to "authenticated";

grant update on table "public"."spatial_ref_sys" to "authenticated";

grant delete on table "public"."spatial_ref_sys" to "postgres";

grant insert on table "public"."spatial_ref_sys" to "postgres";

grant references on table "public"."spatial_ref_sys" to "postgres";

grant select on table "public"."spatial_ref_sys" to "postgres";

grant trigger on table "public"."spatial_ref_sys" to "postgres";

grant truncate on table "public"."spatial_ref_sys" to "postgres";

grant update on table "public"."spatial_ref_sys" to "postgres";

grant delete on table "public"."spatial_ref_sys" to "service_role";

grant insert on table "public"."spatial_ref_sys" to "service_role";

grant references on table "public"."spatial_ref_sys" to "service_role";

grant select on table "public"."spatial_ref_sys" to "service_role";

grant trigger on table "public"."spatial_ref_sys" to "service_role";

grant truncate on table "public"."spatial_ref_sys" to "service_role";

grant update on table "public"."spatial_ref_sys" to "service_role";

grant delete on table "public"."users" to "anon";

grant insert on table "public"."users" to "anon";

grant references on table "public"."users" to "anon";

grant select on table "public"."users" to "anon";

grant trigger on table "public"."users" to "anon";

grant truncate on table "public"."users" to "anon";

grant update on table "public"."users" to "anon";

grant delete on table "public"."users" to "authenticated";

grant insert on table "public"."users" to "authenticated";

grant references on table "public"."users" to "authenticated";

grant select on table "public"."users" to "authenticated";

grant trigger on table "public"."users" to "authenticated";

grant truncate on table "public"."users" to "authenticated";

grant update on table "public"."users" to "authenticated";

grant delete on table "public"."users" to "service_role";

grant insert on table "public"."users" to "service_role";

grant references on table "public"."users" to "service_role";

grant select on table "public"."users" to "service_role";

grant trigger on table "public"."users" to "service_role";

grant truncate on table "public"."users" to "service_role";

grant update on table "public"."users" to "service_role";


  create policy "Users can create chats"
  on "public"."chats"
  as permissive
  for insert
  to public
with check (((auth.uid() = finder_id) OR (auth.uid() = owner_id)));



  create policy "Users can view their chats"
  on "public"."chats"
  as permissive
  for select
  to public
using (((auth.uid() = finder_id) OR (auth.uid() = owner_id)));



  create policy "Allow public inserts"
  on "public"."items"
  as permissive
  for insert
  to public
with check (true);



  create policy "Allow public reads"
  on "public"."items"
  as permissive
  for select
  to public
using (true);



  create policy "Items are viewable by everyone"
  on "public"."items"
  as permissive
  for select
  to public
using (true);



  create policy "Users can create items"
  on "public"."items"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "Users can delete own items"
  on "public"."items"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "Users can update own items"
  on "public"."items"
  as permissive
  for update
  to public
using ((auth.uid() = user_id));



  create policy "Users can update own notifications"
  on "public"."notifications"
  as permissive
  for update
  to public
using ((auth.uid() = user_id));



  create policy "Users can view own notifications"
  on "public"."notifications"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Users can update own profile"
  on "public"."users"
  as permissive
  for update
  to public
using ((auth.uid() = id));



  create policy "Users can view own profile"
  on "public"."users"
  as permissive
  for select
  to public
using ((auth.uid() = id));



  create policy "Anyone can upload images"
  on "storage"."objects"
  as permissive
  for insert
  to anon, authenticated
with check ((bucket_id = 'items'::text));



