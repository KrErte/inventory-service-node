# Inventory Service

A service for managing and querying a simplified technical inventory, with a
**Pharo Smalltalk** backend and a **React** frontend.

This is a port of an earlier Spring Boot 4 / Java 21 implementation. The domain
model, the traversal algorithm and the data-quality policy are unchanged; what
changed is the runtime, and the notes below are mostly about what that cost and
what it bought.

**Live demo:** http://62.171.153.133:8090

HTTP rather than HTTPS, and a port rather than a domain: the host already serves
something else on 80, and Let's Encrypt will not issue a certificate for a bare
IP address.

## Stack

| Concern | Java version | Here |
|---|---|---|
| Runtime | JVM 21 | Pharo 13 |
| Web layer | Spring Boot WebMVC | Teapot (over Zinc HTTP) |
| JSON | Jackson | NeoJSON |
| Dependency injection | Spring container | one method, `InventoryServer >> buildGraph` |
| Tests | JUnit + Mockito + MockMvc | SUnit + ZnClient |
| Build | Gradle | Metacello `BaselineOfInventoryService` |
| Source format | `.java` files | Tonel `.class.st` files, via Iceberg |
| Frontend | — | React 19 + TypeScript + Vite + TanStack Query |

## Layout

```
backend/
  src/
    BaselineOfInventoryService/      the build file, as a class
    InventoryService-Model/          value objects + the one error type
    InventoryService-Core/           repositories, services, loader, HTTP layer
    InventoryService-Tests/          28 unit tests, no sockets
    InventoryService-Tests-Integration/   9 tests over real HTTP
  data/inventory.json                the sample dataset
  Dockerfile
  run-tests.ps1                      headless test run, throwaway image copy
frontend/                            React SPA
.smalltalk.ston                      smalltalkCI configuration
.github/workflows/ci.yml
docker-compose.yml
```

## Running

### Backend, in a development image

Install [Pharo Launcher](https://pharo.org/download), create a Pharo 13 image,
open it and evaluate in a Playground:

```smalltalk
Metacello new
    baseline: 'InventoryService';
    repository: 'tonel://<path to repo>/backend/src';
    load
```

Then start the service:

```smalltalk
InventoryServer new startWithData: '<path to repo>/backend/data/inventory.json' asFileReference
```

It listens on `http://localhost:8080`.

**Save the image afterwards** (`Pharo` → `Save`). Pharo does not save
automatically, and an unsaved image that is closed or killed takes everything
loaded since the last save with it.

### Backend, in Docker

```bash
docker compose up
```

The frontend is published on `http://localhost:3100` and the API on
`http://localhost:8080`. Both host ports are overridable, since 3000 and 8080
collide with something on most machines:

```bash
WEB_PORT=4000 API_PORT=8081 docker compose up
```

The image build loads the project through Metacello and saves the result, so the
container starts by memory-mapping an image that already contains compiled code —
no classpath scan, no framework bootstrap.

There is no maintained official Pharo base image (`pharo/vm` and `pharo/image` on
Docker Hub stopped at Pharo 7 in 2018), so the Dockerfile builds from
`debian:bookworm-slim` and installs Pharo through the zeroconf script. The Pharo
version is a build argument: `docker build --build-arg PHARO_VERSION=140 .`

### Frontend

```bash
cd frontend
npm install
npm run dev
```

Vite serves on `http://localhost:5173` and proxies `/api` to `localhost:8080`, so
the browser only ever sees one origin and there is no CORS configuration to keep
in sync. In production nginx does the same thing (`frontend/nginx.conf`).

## Deployment

On a server with Docker installed:

```bash
git clone https://github.com/KrErte/inventory-service-node.git
cd inventory-service-node
echo "WEB_PORT=8090" > .env
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

`WEB_PORT` is whatever the host has free — the demo above runs on 8090 because
port 80 was already taken on that machine.

Updating later is `git pull` and the same `up -d --build`.

Two things worth knowing before this faces the internet:

- **There is no authentication.** Every endpoint is read-only over a static
  sample dataset, so there is nothing to leak and nothing to modify — but the
  API answers anyone who finds the host.
- **HTTP only.** Let's Encrypt will not issue for a bare IP, so HTTPS needs a
  domain name. With one, putting Caddy in front is the shortest path.

The API container publishes its port on `127.0.0.1` only. Browsers reach it
through nginx inside the compose network, so it never needs a public port.

## API

| Endpoint | Answers |
|---|---|
| `GET /api/v1/locations/{locationId}/equipment` | equipment installed at a location |
| `GET /api/v1/equipment/{equipmentId}/connections` | connections touching a piece of equipment |
| `GET /api/v1/equipment/{equipmentId}/connected?depth={n}` | equipment reachable through active connections, with hop count. Default depth 1 |
| `GET /api/v1/inventory/summary` | counts across the whole inventory |

Every failure answers the same four-key body, whatever went wrong:

```json
{ "status": 404, "error": "Not Found", "message": "Equipment not found: NOPE", "timestamp": "2026-08-30T12:29:35.243Z" }
```

## Key technical decisions

**In-memory storage.** `OrderedDictionary`-backed repositories rather than a
database. The dataset is small and the exercise is about domain modelling. The
ordered dictionary is deliberate, not incidental: several endpoints answer in
file order and the tests assert on it.

**One error type.** `InventoryError` carries an HTTP status, and Teapot has a
single handler for it. The alternative — one exception class per failure mode —
buys nothing at this size and makes the response shape drift between endpoints.

**BFS with the visited set doing double duty.** `depths` maps id → hop count and
is also the visited set, which is what makes cyclic data terminate. Only active
connections are traversed; a piece of equipment being INACTIVE does not block
traversal *through* it, which is what the assignment example implies. The
trailing `includesId:` filter is why `CON-BROKEN` is harmless — it points at
equipment that does not exist, so the traversal never reaches it.

**Symbols as the enum.** `#ACTIVE` / `#INACTIVE`. Symbols are unique and compare
by identity, which is as close as Smalltalk gets to a Java enum without a class
per value.

**Explicit dependency wiring.** `InventoryServer >> buildGraph` constructs six
objects in twelve lines. Pharo has no classpath scanning, and at this size that
is a feature: one file answers "what depends on what" with no indirection.

**Warnings collected, not just logged.** The loader appends to a `warnings`
collection as well as writing to the Transcript. The Java test had to install a
log appender to assert on this behaviour; here the test reads a collection. One
place the port is better than the original.

## Data quality handling

Policy unchanged from the Java version: **warn and load** for broken references,
**fail fast** for structurally broken records.

| Issue | Record | Handling |
|---|---|---|
| Equipment references unknown location | F → LOC-999 | Loaded with warning. The equipment is real; only the pointer is wrong. |
| Connection references unknown equipment | CON-BROKEN → DOES-NOT-EXIST | Loaded with warning. Traversal skips it because the target is not in the store. |
| Duplicate ids | — | First entry wins, duplicate warned about. |
| Missing `id`, unknown `status` | — | Load fails. There is nothing sensible to keep. |
| Cyclic connections | — | Visited set terminates the traversal. |

A test asserts that the sample set produces **exactly two** warnings. If that
number moves, either the data or the policy changed and someone should know.

## Tests

```
InventoryService-Tests               28 tests   domain only, no sockets
InventoryService-Tests-Integration    9 tests   real HTTP against a live server
```

The integration package is **not part of the default load group**. Running a
server inside a development image is genuinely risky: if a socket refuses to
bind, the UI process blocks, the IDE freezes, and killing it loses every unsaved
change in the image. CI asks for the `all` group; a development image does not
get them unless you ask.

Two things learned the hard way and encoded in the tests:

- The server is started **once per test class**, not per test. Nine start/stop
  cycles on the same port in quick succession outrun the operating system's
  socket release, and every test from the sixth onward fails to bind.
- Every HTTP call carries `timeout: 5`, so a wedged request can never hang the
  image indefinitely.

Run them without touching your development image:

```powershell
.\backend\run-tests.ps1              # unit tests
.\backend\run-tests.ps1 -Integration # everything
```

CI runs both through smalltalkCI on a clean image (`.smalltalk.ston`).

## Frontend notes

**The depth view is radial, not force-directed.** A force layout arranges nodes
by connectivity; the endpoint answers *distance from a starting point*. Putting
hop count on the radius makes the `depth` parameter legible — move the slider and
a ring appears. Angle carries no meaning and is not meant to.

**Colour never carries meaning alone.** Depth uses an ordinal single-hue ramp
validated for monotone lightness and contrast against both the light and dark
surfaces; status is a filled dot versus a hollow ring, always beside the word;
and every graph is backed by a table with the same numbers.

**The edges are an N+1.** The API answers which equipment is reachable but not
how the reachable set is wired together, so the graph asks each node for its own
connections. Fine at this size, and TanStack Query caches it, but a production
API would answer the subgraph in one call.

## Known gaps

- **No `GET /api/v1/locations`.** There is no way to list locations, so the
  frontend seeds the two known ids in `api.ts`. The Java version had the same
  gap; it is worked around visibly rather than hidden.
- **No OpenAPI document.** springdoc generated one from Java's runtime types.
  Pharo has no equivalent that pays for itself here, and a hand-written spec that
  drifts is worse than none. The integration tests are the executable contract.
- No pagination, authentication, metrics, filtering or sorting.
- The frontend has no test suite; it is typechecked and built in CI.

## Production improvements

- Replace the in-memory store with PostgreSQL, or Voyage if the object graph
  stays this shape
- Add `GET /api/v1/locations` and a subgraph endpoint for the traversal view
- Pagination on list endpoints
- Structured logging and health checks — `InventoryDataLoader >> log:` is the
  single seam where a real logging framework would go in
- Push images from CI to a registry; the workflow currently builds them only
