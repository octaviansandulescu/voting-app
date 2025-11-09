import os
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import declarative_base, sessionmaker
import time

# Determine if we're in test mode
TESTING = os.getenv("TESTING") == "true"

if TESTING:
    # Use SQLite for testing
    SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        connect_args={"check_same_thread": False}
    )
else:
    # Use MySQL for production
    SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:password@db/votingapp"
    # Retry logic for database connection
    max_retries = 5
    retry_delay = 5  # seconds
    
    for attempt in range(max_retries):
        try:
            engine = create_engine(SQLALCHEMY_DATABASE_URL)
            # Test the connection
            with engine.connect() as connection:
                break
        except Exception as e:
            if attempt == max_retries - 1:
                raise e
            print(f"Database connection attempt {attempt + 1} failed. Retrying in {retry_delay} seconds...")
            time.sleep(retry_delay)

SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

class Vote(Base):
    __tablename__ = "votes"
    id = Column(Integer, primary_key=True, index=True)
    choice = Column(String(50))

# Create tables for both test and production
Base.metadata.create_all(bind=engine)
