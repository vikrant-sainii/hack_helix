from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables from .env if present
load_dotenv()

app = FastAPI(
    title="ISL Sign Enrichment API",
    description="Enriches ISL gloss sequences with high-fidelity keyframes from Supabase"
)

# Supabase Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")

# Initialize Supabase client
supabase: Optional[Client] = None
if SUPABASE_URL and SUPABASE_KEY:
    try:
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    except Exception as e:
        print(f"Failed to initialize Supabase: {e}")

class GlossItem(BaseModel):
    action: str
    duration: float  # In seconds (as received from n8n)

class EnrichRequest(BaseModel):
    glosses: List[GlossItem]

class EnrichedSign(BaseModel):
    gloss: str
    duration_ms: int
    keyframes: List[Dict[str, Any]]
    nmm: Dict[str, Any]

@app.post("/enrich", response_model=Dict[str, List[EnrichedSign]])
async def enrich_glosses(request: EnrichRequest):
    """
    Takes a sequence of glosses and enriches them with animation data from Supabase.
    Performs linear scaling of keyframe timestamps to match requested durations.
    """
    if not supabase:
        raise HTTPException(
            status_code=503, 
            detail="Supabase is not configured. Please set SUPABASE_URL and SUPABASE_KEY."
        )
    
    enriched_sequence = []
    
    for item in request.glosses:
        try:
            # Query the isl_glosses table
            response = supabase.table("isl_glosses") \
                .select("*") \
                .eq("gloss", item.action.upper()) \
                .execute()
            
            if not response.data:
                print(f"Gloss not found in database: {item.action}")
                # We skip missing glosses for now so the sequence doesn't break
                continue
                
            db_data = response.data[0]
            db_duration = float(db_data.get("duration", 1.0))
            db_keyframes = db_data.get("keyframes", [])
            db_nmm = db_data.get("nmm", {"face": "neutral", "head": "neutral"})
            
            # --- Keyframe Scaling Logic ---
            # If DB duration is 1.0s and requested is 1.5s, scale_factor = 1.5
            scale_factor = item.duration / db_duration if db_duration > 0 else 1.0
            
            scaled_keyframes = []
            for kf in db_keyframes:
                new_kf = kf.copy()
                if "time" in kf:
                    # Rounding to 3 decimal places for precision/cleanliness
                    new_kf["time"] = round(float(kf["time"]) * scale_factor, 3)
                scaled_keyframes.append(new_kf)
            
            # Construct the enriched sign
            # duration_ms is converted to milliseconds for Three.js
            enriched_sequence.append(EnrichedSign(
                gloss=item.action,
                duration_ms=int(item.duration * 1000),
                keyframes=scaled_keyframes,
                nmm=db_nmm
            ))
            
        except Exception as e:
            print(f"Error processing gloss '{item.action}': {e}")
            continue
            
    return {"sequence": enriched_sequence}

@app.get("/health")
def health_check():
    return {
        "status": "online",
        "supabase_connected": supabase is not None,
        "environment": "production" if os.getenv("RENDER") else "development"
    }

if __name__ == "__main__":
    import uvicorn
    # Local dev run
    uvicorn.run(app, host="0.0.0.0", port=8000)
