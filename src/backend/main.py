from typing import Generator
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from database import SessionLocal, Vote
from sqlalchemy.orm import Session

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class VoteModel(BaseModel):
    choice: str

@app.post("/vote")
def cast_vote(vote: VoteModel, db: Session = Depends(get_db)):
    if vote.choice not in ['dog', 'cat']:
        raise HTTPException(status_code=400, detail="Invalid choice")
    
    new_vote = Vote(choice=vote.choice)
    db.add(new_vote)
    db.commit()
    return {"message": "Vote recorded"}

@app.get("/results")
def get_results(db: Session = Depends(get_db)):
    dogs = db.query(Vote).filter(Vote.choice == "dog").count()
    cats = db.query(Vote).filter(Vote.choice == "cat").count()
    return {"dogs": dogs, "cats": cats}
