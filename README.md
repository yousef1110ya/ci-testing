# ci-test-app

A minimal Gin "ping → pong" web app, with Kubernetes manifests and a GitHub
Actions pipeline that builds the Docker image and ships it to a node over SSH.

## The app

| Endpoint   | Response            |
|------------|---------------------|
| `GET /ping`    | `pong`          |
| `GET /healthz` | `{"status":"ok"}` (used by the probes) |

Listens on `:8080` (override with `PORT`).

## Layout

```
main.go                      # the Gin app
Dockerfile                   # multi-stage build -> distroless image
k8s/
  namespace.yaml             # the ci-test namespace
  deployment.yaml            # Deployment (1 replica) in ci-test
  service.yaml               # ClusterIP Service in ci-test (no ingress)
.github/workflows/deploy.yml # build + SSH deploy pipeline
```

Everything runs in the **`ci-test`** namespace.

## CI/CD

Runs on push to `main`/`master` and on manual trigger (`workflow_dispatch`).
It **clones the source from a private Codeberg repo** (over HTTPS with
username/password), builds the image, `docker save`s it, pipes it over SSH
into the node's containerd (`ctr -n k8s.io images import`), applies the
manifests, then `set image` + `rollout status` to roll out
`ci-test-app:<git-sha>`.

Required repository **secrets**:

| Secret              | Meaning                                              |
|---------------------|------------------------------------------------------|
| `CODEBERG_REPO`     | Codeberg repo slug, format `owner/repo`              |
| `CODEBERG_USERNAME` | Codeberg username                                    |
| `CODEBERG_PASSWORD` | Codeberg password or access token                    |
| `NODE_HOST`         | node hostname / IP                                   |
| `NODE_USER`         | SSH user                                             |
| `NODE_SSH_KEY`      | private SSH key for that user                        |
| `NODE_KNOWN_HOSTS`  | `known_hosts` entry for the node (ssh-keyscan)       |

The `master` branch is cloned. Credentials are passed via `GIT_ASKPASS`, so
they never appear in the command line or the build logs.

The SSH user needs `sudo ctr` and `kubectl` access on the node.

## Testing it (port-forward, no ingress)

```bash
kubectl -n ci-test port-forward svc/ci-test-app 8080:80
curl localhost:8080/ping   # -> pong
```
