# Abla Web

Abla Web is the application framework above Abla's HTTP, WebSocket, RPC, and
event-driven networking libraries. It complements `abla-mvc`: MVC owns HTML
views and browser actions, while Abla Web owns service composition, API route
groups, middleware, authentication boundaries, and backend integrations.

## Current API

```abla
import github("AndreBaltazar8/abla-web")
import "abla/http/event"

fun profile(context: WebContext): HttpResponse = webJson(
    "{\"id\":\"${context.parameter("id")}\"}"
)

fun main: int {
    val app = webApp()
    app.use(webSecurityHeaders())
    app.use(webCors(webCorsOptions("https://app.example")))

    val api = app.group("/api/v1")
    api.use(webBodyLimit(32768))
    api.get("/profiles/:id", profile)

    val handleRequest = { request: HttpRequest -> webDispatch(app, request) }
    val server = httpEventServerHandler(handleRequest, ipv4Any(8080))
    server.run()
}
```

Middleware is ordered, composable, and can short-circuit or wrap downstream
handlers. Nested groups inherit middleware and prefixes. The first package
slice includes security headers, CORS/preflight, bearer authentication,
bounded bodies, cookie/session helpers, CSRF protection, callback-backed rate
limiting, request identity, access logs, metrics hooks, liveness/readiness
checks, and compatible `/rpc/:method` routes for existing Abla Mobile clients.

`src/build.ab` can generate a complete event-driven service from imported
`@rpc (string) -> string` actions. This retains the existing typed Abla Mobile
contract while moving routing, middleware, health checks, persistent HTTP, and
backpressure policy into Abla Web.

The generated server uses Abla's bounded event runtime, persistent HTTP,
backpressure, idle deadlines, and graceful draining.

## Region-backed hot path

Services whose handlers do not retain request data can opt into a whole-request
allocation region. The callable effect is checked by the compiler rather than
trusted at runtime:

```abla
noescape fun plaintext(context: WebContext): HttpResponse =
    httpText("hello, world!\n")

noescape fun handle(request: HttpRequest): HttpResponse =
    webNoEscapeRoute(request, "GET", "/plaintext", plaintext)

fun main: int {
    val server = httpEventServerNoEscapeHandler(
        handle,
        ipv4Any(8080)
    )
    server.run()
}
```

`webNoEscapeRoute` supports exact routes, path parameters, method rejection,
and GET-to-HEAD fallback. It intentionally excludes middleware and dynamic
route mutation; use `WebApp` for those features. Parsing, routing, handler work,
and response framing occur inside one bump region, with only the final encoded
response promoted to the connection output queue.

## Service integrations

The committed dependency locks pin the official Abla clients, and the package
exposes small service-level adapters:

- `WebPostgresPool` keeps a bounded round-robin set of authenticated wire
  sessions and runs idempotent migration statements;
- `WebRedisStore` supplies a reusable connection, health checks, and atomic
  fixed-window rate-limit decisions; and
- `WebNatsJobs` publishes and requests namespaced Core NATS jobs.

All three expose readiness results that plug into `WebHealthRegistry`. Redis
rate limiting separates the stateful store call from middleware composition,
which lets an application retain its client in an ownership-safe service
boundary and choose fail-open or fail-closed behavior explicitly.

## Development

Build `../ablac`, then run:

```sh
make check
make example
```

To intentionally update dependencies, run:

```sh
../ablac/build/ablac package update --project .
../ablac/build/ablac package update --project tests
```

Ordinary builds consume committed locks; they do not contact GitHub or silently
advance dependencies. Applications importing Abla Web also pin its transitive
clients in the application's own lock.

Licensed under the Mozilla Public License 2.0.
