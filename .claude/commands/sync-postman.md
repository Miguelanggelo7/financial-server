---
description: Syncs Postman with the current `openapi.yaml` of the project.
model: claude-sonnet-4.5
---

## Hardcoded IDs
- Spec: `9baf9355-5a8a-4bda-a5d9-c8f0c2dccc12`
- Collection: `f2b3e0f0-d046-4e27-b3e1-2d55a70efbe0` (prefixed: `43952046-f2b3e0f0-d046-4e27-b3e1-2d55a70efbe0`)
- Environment: `454c17d6-1c40-41c3-a295-f633cab99e3d`

## Step 1 — Upload spec to Postman

Read the project's `openapi.yaml` and upload it with `mcp__postman__updateSpecFile`:
- `specId`: `9baf9355-5a8a-4bda-a5d9-c8f0c2dccc12`
- `path`: `openapi.yaml`
- Content: the current `openapi.yaml`

## Step 2 — Sync collection

Use `mcp__postman__syncCollectionWithSpec`:
- `specId`: `9baf9355-5a8a-4bda-a5d9-c8f0c2dccc12`
- `collectionId`: `43952046-f2b3e0f0-d046-4e27-b3e1-2d55a70efbe0`

## Step 3 — Reapply scripts

Use `mcp__postman__updateCollectionRequest` with `collectionId`: `f2b3e0f0-d046-4e27-b3e1-2d55a70efbe0` for these requests:

**Sign Up** — `auth: { type: "noauth" }`

**Sign In** — `auth: { type: "noauth" }` + test script:
```js
const token = pm.response.headers.get('Authorization');
if (token) {
  pm.environment.set('bearerToken', token.replace('Bearer ', ''));
}
```

**Sign Out** — test script:
```js
pm.environment.unset('bearerToken');
```

**List Categories** — test script:
```js
const data = pm.response.json();
if (data.length > 0) {
  pm.environment.set('category_id', data[0].id);
}
```

**Create Category** — test script:
```js
const data = pm.response.json();
if (data.id) {
  pm.environment.set('category_id', data.id);
}
```

## Step 4 — Confirm

Briefly summarize what was synced in Postman.
