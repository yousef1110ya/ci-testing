# ---- build stage ----
FROM golang:1.23-alpine AS build

WORKDIR /src

COPY . .

# Resolve deps and write go.sum (no go.sum is committed), then build.
RUN go mod tidy

# Static build so it runs on a minimal base image.
RUN CGO_ENABLED=0 GOOS=linux go build -o /ci-test-app .

# ---- runtime stage ----
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /ci-test-app /ci-test-app

EXPOSE 8080
USER nonroot:nonroot

ENTRYPOINT ["/ci-test-app"]
