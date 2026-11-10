"""Minimal health-oriented API used by the EKS deployment demo."""
from fastapi import FastAPI

app = FastAPI(title="DevOps Demo API", version="1.0.0")


@app.get("/", tags=["general"])
def root() -> dict[str, str]:
    return {"message": "Hello from Kubernetes!"}


@app.get("/health", tags=["operations"])
def health() -> dict[str, str]:
    return {"status": "healthy"}


@app.get("/version", tags=["general"])
def version() -> dict[str, str]:
    return {"version": app.version}
