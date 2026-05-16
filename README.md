# Reception App

Modern reception and check-in software built with Flutter, Riverpod, and Supabase.

This project is a lightweight front-desk system for managing people, check-ins, activity logs, and CSV-based roster imports across desktop and web. It is designed to feel fast, simple, and operational from day one.

## Why This Project

Reception App focuses on a small but practical workflow:
- maintain a searchable people roster
- check guests or members in with notes
- handle batch check-in and check-out actions
- review recent activity in a clean log view
- import people from CSV without extra admin tooling
- deploy the same experience to web with Vercel

It is intentionally opinionated:
- Flutter for one codebase across platforms
- Riverpod for predictable state flow
- Supabase for storage and serverless extensions
- simple table design that is easy to reason about

## Features

- Fast people search and status filtering
- Single and batch check-in workflows
- Batch check-out support
- Live activity log with search and note filtering
- CSV import with optional IDs
- Automatic ID generation for new imported people
- Responsive shell navigation for mobile and desktop layouts
- Weather indicator powered by a Supabase Edge Function
- Production-friendly startup validation for env and schema issues

## Demo Architecture

The app follows a clean UI -> state -> service -> data flow:

```text
Screens / Widgets
        |
        v
Riverpod Providers + Notifiers
        |
        v
Services
        |
        v
Supabase Tables + Edge Functions
```

Core layers:
- `lib/screens`: top-level product areas
- `lib/widgets`: reusable UI components
- `lib/providers`: Riverpod state orchestration
- `lib/services`: Supabase reads, writes, and CSV parsing
- `lib/models`: typed app data
- `lib/core`: app bootstrap, routing, theme, schema checks, utilities

## Product Areas

### Check-In

The main workflow surface for front-desk staff.

What it supports:
- tap-to-check-in for a single person
- optional notes during check-in
- batch select mode
- batch check-in
- batch check-out
- single or bulk deletion
- filter by checked-in status
- sort by name or recent activity

Primary files:
- [lib/screens/checkin_screen.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/screens/checkin_screen.dart)
- [lib/providers/people_provider.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/providers/people_provider.dart)
- [lib/providers/checkin_provider.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/providers/checkin_provider.dart)

### Log

The log screen gives operators a quick view into recent activity.

What it supports:
- search by person name
- search by notes
- filter entries that contain notes
- chronological activity display using `checked_in_at`

Primary files:
- [lib/screens/log_screen.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/screens/log_screen.dart)
- [lib/widgets/log_table.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/widgets/log_table.dart)

### Admin

The admin area is focused on data import.

What it supports:
- browser-based CSV upload
- UTF-8 CSV decoding
- `first_name,last_name` parsing
- optional `id` column support
- upsert for rows with IDs
- generated IDs for rows without IDs

Primary files:
- [lib/screens/admin_screen.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/screens/admin_screen.dart)
- [lib/services/csv_parser.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/services/csv_parser.dart)
- [lib/services/people_service.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/services/people_service.dart)
- [lib/core/person_id_generator.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/core/person_id_generator.dart)

## Stack

- Flutter
- Material 3
- Flutter Riverpod
- GoRouter
- Supabase
- Supabase Edge Functions
- Vercel

## Project Structure

```text
lib/
  core/        App bootstrap, theme, router, schema validation, utilities
  models/      Typed app models
  providers/   Riverpod providers and notifiers
  screens/     Top-level app screens
  services/    Data access and CSV parsing
  widgets/     Shared UI building blocks

supabase/
  functions/   Edge functions
  migrations/  SQL schema source of truth

sample_data/   Ready-to-import CSV examples
scripts/       Deployment scripts
test/          Widget and parser coverage
```

## Routing

Navigation is handled with `GoRouter` using an indexed shell route.

Routes:
- `/` -> Check-In
- `/log` -> Log
- `/admin` -> Admin

Responsive behavior:
- wide screens use `NavigationRail`
- smaller screens use `NavigationBar`

Primary file:
- [lib/core/router.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/core/router.dart)

## State Management

Riverpod drives both async loading and derived UI state.

Important provider groups:
- `peopleProvider`: loads and mutates roster data
- `checkInProvider`: loads and mutates active check-ins
- `visiblePeopleProvider`: combines search, filters, sorting, and check-in state
- `currentWeatherProvider`: fetches weather summary for the header indicator

Primary files:
- [lib/providers/people_provider.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/providers/people_provider.dart)
- [lib/providers/checkin_provider.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/providers/checkin_provider.dart)
- [lib/providers/weather_provider.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/providers/weather_provider.dart)

## Data Model

### `people`

Canonical roster table.

Columns:
- `id text primary key`
- `first_name text not null`
- `last_name text not null`

### `checkins`

Current and recent check-in activity table.

Columns:
- `id bigint generated by default as identity primary key`
- `person_id text not null references public.people (id) on delete cascade`
- `first_name text not null`
- `last_name text not null`
- `checked_in_at timestamptz not null default now()`
- `notes text not null default ''`

Current behavior:
- a person is considered checked in if they have an entry in `checkins`
- checking out removes matching `checkins` rows
- this keeps the model simple, though it is not a full audit/event system

Migration source:
- [supabase/migrations/20260516_create_reception_tables.sql](/Users/carldeeik/Vibe-Coding-Demo/supabase/migrations/20260516_create_reception_tables.sql)

## Environment Variables

Local `.env`:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
WEATHER_LOCATION=auto:ip
```

Required:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Optional:
- `WEATHER_LOCATION`

Important:
- local `.env` files use `KEY=value`
- Vercel env fields should contain only the raw value
- `SUPABASE_URL` and `SUPABASE_ANON_KEY` must come from the same Supabase project

## Quick Start

### 1. Clone and install

```bash
flutter pub get
```

### 2. Create your env file

Copy [.env.example](/Users/carldeeik/Vibe-Coding-Demo/.env.example) to `.env` and fill in the values.

### 3. Create the required tables

Run this SQL in the Supabase SQL editor:

```sql
create table if not exists public.people (
  id text primary key,
  first_name text not null,
  last_name text not null
);

create table if not exists public.checkins (
  id bigint generated by default as identity primary key,
  person_id text not null references public.people (id) on delete cascade,
  first_name text not null,
  last_name text not null,
  checked_in_at timestamptz not null default now(),
  notes text not null default ''
);
```

### 4. Run locally

```bash
flutter run -d chrome
```

Useful commands:

```bash
flutter analyze
flutter test
flutter build web --release
```

## Deployment

This project is configured for Vercel web deployment.

Relevant files:
- [vercel.json](/Users/carldeeik/Vibe-Coding-Demo/vercel.json)
- [scripts/vercel-build.sh](/Users/carldeeik/Vibe-Coding-Demo/scripts/vercel-build.sh)

Build flow:
1. install Flutter in the build environment
2. run `flutter pub get`
3. generate `.env` from deployment environment variables
4. run `flutter build web --release`
5. publish `build/web`

Vercel environment variables:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `WEATHER_LOCATION` optional

Important deployment note:
- after changing Vercel env vars, redeploy

## Startup Validation

The app performs eager startup checks so setup issues fail fast.

Startup sequence:
1. load `.env`
2. validate Supabase URL and anon key
3. initialize Supabase
4. validate the required schema
5. render the app shell

Primary files:
- [lib/main.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/main.dart)
- [lib/core/supabase_client.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/core/supabase_client.dart)
- [lib/core/schema_validator.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/core/schema_validator.dart)

## CSV Import

Accepted format:

```csv
id,first_name,last_name
person_lina_haddad,Lina,Haddad
person_omar_nasser,Omar,Nasser
```

Rules:
- `first_name` is required
- `last_name` is required
- `id` is optional
- rows with `id` are upserted
- rows without `id` are inserted as new people with generated IDs

Sample import file:
- [sample_data/reception_people_import.csv](/Users/carldeeik/Vibe-Coding-Demo/sample_data/reception_people_import.csv)

## Weather Function

The weather badge is powered by a Supabase Edge Function.

Flow:
1. read `WEATHER_LOCATION`
2. default to `auto:ip` if missing
3. invoke the `weather` function
4. map the response into a `WeatherSnapshot`

Primary files:
- [lib/core/weather_api.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/core/weather_api.dart)
- [lib/providers/weather_provider.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/providers/weather_provider.dart)
- [supabase/functions/weather/index.ts](/Users/carldeeik/Vibe-Coding-Demo/supabase/functions/weather/index.ts)

## Testing

Current coverage includes:
- widget smoke testing
- CSV sample-file parsing
- generated ID behavior

Relevant tests:
- [test/widget_test.dart](/Users/carldeeik/Vibe-Coding-Demo/test/widget_test.dart)
- [test/csv_parser_sample_file_test.dart](/Users/carldeeik/Vibe-Coding-Demo/test/csv_parser_sample_file_test.dart)
- [test/person_id_generator_test.dart](/Users/carldeeik/Vibe-Coding-Demo/test/person_id_generator_test.dart)

## Troubleshooting

### `Supabase is not configured`

Usually means:
- `.env` is missing
- placeholder values are still in use
- Vercel env vars are unset

### `Invalid API key` or PostgREST `401`

Usually means:
- the anon key is wrong
- the key was pasted as `SUPABASE_ANON_KEY=value` instead of just the value
- the key and URL belong to different Supabase projects

### `Could not find the table 'public.people'`

Usually means:
- the SQL schema was not created in the target project
- the app is pointed at the wrong Supabase instance

### `null value in column "id" of relation "people"`

Usually means:
- an older build is still running
- the importer was used before a hot restart or redeploy after the ID-generation fix

### `xcodebuild` not found

Usually means:
- the macOS target was selected without Xcode command line tools installed

## Known Tradeoffs

- check-out is modeled as deletion from `checkins`
- names are duplicated into `checkins` for simpler log rendering
- startup checks are eager to improve setup visibility
- CSV import is currently client-side

These choices keep the app easy to understand, but they also leave room for future upgrades like:
- explicit check-out events
- role-based access control
- richer migration/versioning strategy
- more complete integration coverage

## Contributing

If you are extending the project, a good next place to look is:
- [lib/main.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/main.dart)
- [lib/core/router.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/core/router.dart)
- [lib/providers/people_provider.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/providers/people_provider.dart)
- [lib/services/people_service.dart](/Users/carldeeik/Vibe-Coding-Demo/lib/services/people_service.dart)

That path gives a quick understanding of app startup, routing, state flow, and persistence.
