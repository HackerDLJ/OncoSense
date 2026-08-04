from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    APP_NAME: str = "OncoSense"

    DEBUG: bool = True

    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str = "oncosense"
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"

    MONGODB_URI: str = "mongodb://localhost:27017"

    OPENAI_API_KEY: str = ""

    OLLAMA_BASE_URL: str = "http://localhost:11434"

    JWT_SECRET_KEY: str = "super_secret_key_change_me"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore"
    )

settings = Settings()