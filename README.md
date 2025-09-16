# hello-http

A simple HTTP server for demonstrating GitOps deployment pipeline.

## Overview

This is a trivial HTTP server that responds with a configurable message. It's designed to demonstrate a GitOps deployment pipeline where:

1. Changes to this repo trigger CI
2. CI builds the server and notifies the configs repo
3. The configs repo updates its flake.lock to pin this exact version
4. The Hetzner server pulls the update and deploys automatically

## Running Locally

```bash
# Build the server
nix build .#server

# Run the server
nix run .#server

# Or with custom message
HELLO_MSG="Custom message" PORT=8080 nix run .#server
```

## Environment Variables

- `PORT` - Port to listen on (default: 9000)
- `HELLO_MSG` - Message to return (default: "Hello from GitOps v1")

## Testing Changes

1. Modify the default message in `flake.nix`
2. Commit and push to main
3. CI will build and notify the configs repo
4. Watch the server update automatically

## CI/CD Flow

```mermaid
graph LR
    A[Push to hello-http] --> B[GitHub Actions CI]
    B --> C[Build & Test]
    C --> D[Dispatch to configs repo]
    D --> E[configs updates flake.lock]
    E --> F[Hetzner pulls update]
    F --> G[Service restarts]
```