
from fastapi import FastAPI

app = FastAPI(title="BookNest API")


@app.get("/")
def home():
    return {"message": "Welcome to BookNest API"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}
