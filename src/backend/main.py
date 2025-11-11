"""
🎯 Voting App Backend - FastAPI Application

Ce face:
1. API endpoint pentru vot (/vote)
2. API endpoint pentru rezultate (/results)
3. Conectare la MySQL
4. Validare date
5. Error handling

Concepte DevOPS introduse:
- REST API design
- Database interaction
- Error handling
- Logging
- CORS security
- Configuration management
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import logging
from datetime import datetime
import os

# Import din config local
try:
    from config import DATABASE_URL, DEPLOYMENT_MODE
except ImportError:
    # Fallback la environment variables
    DATABASE_URL = os.getenv("DATABASE_URL", "mysql+pymysql://voting_user:password@localhost:3306/voting_app")
    DEPLOYMENT_MODE = os.getenv("DEPLOYMENT_MODE", "local")

from database import Database

# ============================================================================
# 1. LOGGING SETUP - DevOPS Practice: Structured Logging
# ============================================================================

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

logger.info(f"[STARTUP] Deployment Mode: {DEPLOYMENT_MODE}")
logger.info(f"[STARTUP] Application starting...")

# ============================================================================
# 2. FASTAPI APP INITIALIZATION
# ============================================================================

app = FastAPI(
    title="Voting App API",
    description="Simple voting application backend",
    version="1.0.0"
)

# ============================================================================
# 3. CORS MIDDLEWARE - Security Practice
# ============================================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Restrict to frontend URL in production
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# ============================================================================
# 4. DATA MODELS - Pydantic Validation
# ============================================================================

class VoteRequest(BaseModel):
    """Model pentru vote request"""
    vote: str

    class Config:
        json_schema_extra = {
            "example": {"vote": "dogs"}
        }


class ResultsResponse(BaseModel):
    """Response model pentru /results endpoint"""
    dogs: int
    cats: int
    total: int

# ============================================================================
# 5. DATABASE INITIALIZATION
# ============================================================================

db = None

@app.on_event("startup")
async def startup_event():
    """Initialize database at app startup"""
    global db
    try:
        db = Database()
        logger.info("[STARTUP] Database initialized successfully")
    except Exception as e:
        logger.error(f"[STARTUP] Failed to initialize database: {str(e)}")
        raise


@app.on_event("shutdown")
async def shutdown_event():
    """Close database connection at app shutdown"""
    global db
    if db:
        try:
            db.close()
            logger.info("[SHUTDOWN] Database connection closed")
        except Exception as e:
            logger.error(f"[SHUTDOWN] Error closing database: {str(e)}")

# ============================================================================
# 6. HEALTH CHECK ENDPOINT
# ============================================================================

@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring"""
    try:
        if not db or not db.is_connected():
            logger.warning("[HEALTH] Database not connected")
            raise HTTPException(status_code=503, detail="Database connection failed")
        
        return {"status": "ok", "mode": DEPLOYMENT_MODE}
    except Exception as e:
        logger.error(f"[HEALTH] Error: {str(e)}")
        raise HTTPException(status_code=503, detail="Service unavailable")

# ============================================================================
# 7. VOTE ENDPOINT - POST /vote
# ============================================================================

@app.post("/vote")
async def vote(vote_request: VoteRequest):
    """Record a vote"""
    
    try:
        # Validate vote
        vote_lower = vote_request.vote.lower().strip()
        
        if vote_lower not in ['dogs', 'cats']:
            logger.warning(f"[VOTE] Invalid vote received: {vote_request.vote}")
            raise HTTPException(
                status_code=400,
                detail="Vote must be 'dogs' or 'cats'"
            )
        
        # Insert vote
        logger.info(f"[VOTE] Recording vote: {vote_lower}")
        db.insert_vote(vote_lower)
        
        return {
            "success": True,
            "message": "Vote recorded successfully"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[VOTE] Error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")

# ============================================================================
# 8. RESULTS ENDPOINT - GET /results
# ============================================================================

@app.get("/results", response_model=ResultsResponse)
async def get_results():
    """Get current vote results"""
    
    try:
        logger.info("[RESULTS] Fetching vote results")
        results = db.get_results()
        
        dogs_count = results.get('dogs', 0)
        cats_count = results.get('cats', 0)
        total_count = dogs_count + cats_count
        
        logger.info(f"[RESULTS] Dogs: {dogs_count}, Cats: {cats_count}")
        
        return ResultsResponse(
            dogs=dogs_count,
            cats=cats_count,
            total=total_count
        )
    
    except Exception as e:
        logger.error(f"[RESULTS] Error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail="Failed to fetch results")

# ============================================================================
# 9. ROOT ENDPOINT
# ============================================================================

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Voting App API",
        "version": "1.0.0",
        "mode": DEPLOYMENT_MODE,
        "endpoints": {
            "health": "/health",
            "vote": "POST /vote",
            "results": "GET /results",
            "docs": "/docs"
        }
    }

# ============================================================================
# 10. ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    """Run directly (for local development)"""
    import uvicorn
    
    logger.info("[MAIN] Starting application")
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
