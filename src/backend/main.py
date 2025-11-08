from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from database import SessionLocal, Vote

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class VoteModel(BaseModel):
    choice: str

@app.post("/vote")
def cast_vote(vote: VoteModel):
    if vote.choice not in ['dog', 'cat']:
        raise HTTPException(status_code=400, detail="Invalid choice")
    
    db = SessionLocal()
    new_vote = Vote(choice=vote.choice)
    db.add(new_vote)
    db.commit()
    db.close()
    return {"message": "Vote recorded"}

@app.get("/results")
def get_results():
    db = SessionLocal()
    dogs = db.query(Vote).filter(Vote.choice == "dog").count()
    cats = db.query(Vote).filter(Vote.choice == "cat").count()
    db.close()
    return {"dogs": dogs, "cats": cats}
