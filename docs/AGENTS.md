# AGENTS

This file defines project rules for AI coding agents such as Codex, Claude, or other agentic development tools.

## 1. Required Reading Before Any Development

Before making code changes, read:

1. `DEVELOPMENT_HANDOFF.md`
2. `outputs/pet-memorial-prototype/index.html`
3. `outputs/development-docs/01_product_scope_summary.md`
4. `outputs/development-docs/02_pages_and_routes.md`
5. `outputs/development-docs/03_data_model.md`
6. `outputs/development-docs/04_api_spec.md`
7. `outputs/development-docs/05_state_machine.md`
8. `outputs/development-docs/10_open_questions_and_risks.md`

## 2. HTML Prototype Rule

The HTML prototype is not production code.

Use it only as a reference for:

- page structure;
- interaction paths;
- state transitions;
- App/H5 relationship;
- mock data flow;
- development walkthrough states.

Do not directly port the prototype as production App, H5, or backend code.

## 3. Source Of Truth

The PRD and documented product boundary have higher priority than the HTML mock implementation.

If the HTML mock conflicts with the PRD or the development docs, follow:

1. PRD/product boundary;
2. `DEVELOPMENT_HANDOFF.md`;
3. development docs under `outputs/development-docs/`;
4. HTML prototype as interaction reference only.

## 4. Do Not Add Undefined Features

Do not add the following unless the user explicitly changes V1 scope:

- community;
- discovery page;
- message center;
- comments;
- visitor messages;
- AI chat;
- pet replies;
- pet resurrection;
- task system;
- points;
- rankings;
- marketplace/shop;
- complex multi-pet management;
- system Push;
- anniversary reminders;
- video upload;
- AI animated pet.

## 5. Undefined Problems

If a requirement is not defined in PRD, handoff, or docs:

- do not invent product scope;
- do not silently implement adjacent features;
- list it as an open question;
- ask the user when needed.

## 6. V1 Scope

V1 only includes:

- iOS App main flow;
- H5 visitor page;
- single-pet creation;
- home planet observation window;
- memory page;
- TA's story;
- album;
- paid heaven mailbox;
- H5 sharing;
- visitor hug;
- owner hug records;
- Mine tab management;
- free/paid entitlement;
- permission settings.

## 7. Implementation Invariants

When implementing code, preserve these rules:

- Free tier must fully support creation, sharing, and hug loop.
- Paid tier only enhances photo capacity and heaven mailbox.
- Hug records must be fully visible to both free and paid users.
- H5 visitors do not need to log in.
- Letters must not appear on the public H5 page.
- Entitlement is bound to the account, not a single pet.
- All content objects must keep `pet_id` for future multi-pet expansion.
- V1 supports only one pet in UI, even if data models are multi-pet ready.
- H5 access must be controlled by share/permission state.
- Visitor hug deduplication must be handled by backend in real implementation.

## 8. Visual Design Rule

Do not perform visual redesign in the first implementation stage unless the user explicitly requests it.

Preserve the current direction:

- warm;
- natural;
- restrained;
- memorial;
- not social/community-like;
- not task/game-like;
- not AI chat-like;
- not funeral-service-like;
- not aggressive upsell.

## 9. Development Priorities

Start with P0:

1. account;
2. single-pet creation;
3. main photo;
4. home;
5. memory page;
6. H5 access;
7. sharing;
8. hug;
9. hug records;
10. permission;
11. basic free/paid entitlement checks.

Use `outputs/development-docs/09_development_roadmap.md` for detailed sequencing.

## 10. File Safety

Do not modify `outputs/pet-memorial-prototype/index.html` unless the user explicitly asks to continue editing the prototype.

Do not expand the 10 development docs unless the user explicitly asks.

Do not start production code unless the user explicitly asks for implementation.

