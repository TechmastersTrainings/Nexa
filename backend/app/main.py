import logging
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from app.api.v1.router import api_router
from app.core.config import settings
from app.core.database import Base, engine
import app.models  # ensure models are registered with Base

logger = logging.getLogger(__name__)

# Automatically create schema on startup with resilient error boundary
try:
    Base.metadata.create_all(bind=engine)
    logger.info("Database schema verified and created successfully.")
except Exception as e:
    logger.error(f"Database schema initialization warning: {e}", exc_info=True)

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Backend API services for AI-Based Intelligent Women Safety Assistant Monorepo",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# CORS Middleware setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Consistent error handling for validation errors
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = []
    for err in exc.errors():
        field = " -> ".join(str(loc) for loc in err["loc"] if loc != "body")
        errors.append({
            "field": field,
            "message": err["msg"],
            "type": err["type"]
        })
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "success": False,
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Invalid request parameters or payload format.",
                "details": errors
            }
        }
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled error processing {request.method} {request.url.path}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "detail": f"{type(exc).__name__}: {str(exc)}"
        }
    )


# Include API v1 router
app.include_router(api_router, prefix=settings.API_V1_PREFIX)


@app.on_event("startup")
def on_startup():
    try:
        import app.models
        Base.metadata.create_all(bind=engine)
        logger.info(f"Startup: database tables verified on {engine.dialect.name}.")
    except Exception as e:
        logger.error(f"Startup: database schema creation error: {e}", exc_info=True)


@app.api_route("/", methods=["GET", "HEAD"], summary="Root Status")
def root():
    return {
        "service": settings.PROJECT_NAME,
        "version": "1.0.0",
        "status": "online",
        "docs": "/docs",
        "api_v1": settings.API_V1_PREFIX
    }


@app.api_route("/health", methods=["GET", "HEAD"], summary="Health Check")
def health():
    return {"status": "healthy", "service": settings.PROJECT_NAME}
