from typing import List, Union
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    PROJECT_NAME: str = "Nexa Women Safety Intelligence Platform"
    API_V1_PREFIX: str = "/api/v1"

    # Security
    SECRET_KEY: str = "nexa_women_safety_assistant_super_secure_jwt_secret_key_prod_grade_2026_random_string"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 14

    # Database
    POSTGRES_SERVER: str = "127.0.0.1"
    POSTGRES_PORT: int = 5432
    POSTGRES_USER: str = "nexa_user"
    POSTGRES_PASSWORD: str = "nexa_secure_password_2026"
    POSTGRES_DB: str = "nexa_safety_db"
    DATABASE_URL: str = "postgresql+psycopg2://nexa_user:nexa_secure_password_2026@127.0.0.1:5432/nexa_safety_db"

    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:3000",
        "http://10.0.2.2:8000",
    ]

    # Emergency Services (Phase 5)
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_FROM_PHONE: str = ""
    EMERGENCY_SMS_ENABLED: bool = False

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            if isinstance(v, str):
                import json
                try:
                    return json.loads(v)
                except Exception:
                    return [i.strip() for i in v.split(",") if i.strip()]
            return v
        return []

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )


settings = Settings()
