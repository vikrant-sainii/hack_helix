"""
FastAPI backend for ISL Sign Language enrichment.

Endpoint: POST /enrich
- Receives ISL gloss list from Flutter (duration in SECONDS from n8n)
- Looks up keyframes + NMM from Supabase isl_glosses table
- Converts duration: seconds → milliseconds (ONLY HERE, never elsewhere)
- Returns enriched sequence to Flutter

TODO: Implement after Supabase credentials are added to .env
Run with: uvicorn main:app --reload --port 8000
"""

import os
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Any

load_dotenv()

# TODO: Uncomment when .env is configured
# from supabase import create_client, Client
# supabase: Client = create_client(
#     os.getenv("SUPABASE_URL", ""),
#     os.getenv("SUPABASE_ANON_KEY", ""),
# )

app = FastAPI(title="ISL Enrich API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Lock to Flutter app origin in production
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Request / Response Models ────────────────────────────────────────────────

class GlossInput(BaseModel):
    action: str
    duration: float  # SECONDS — as received from n8n, never convert here


class EnrichRequest(BaseModel):
    glosses: List[GlossInput]


class EnrichedSign(BaseModel):
    gloss: str
    duration_ms: int          # MILLISECONDS — converted FROM seconds ONLY here
    keyframes: List[Any]
    nmm: dict


class EnrichResponse(BaseModel):
    sequence: List[EnrichedSign]


# ─── Endpoints ────────────────────────────────────────────────────────────────

@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/enrich", response_model=EnrichResponse)
async def enrich(request: EnrichRequest):
    """
    Takes ISL gloss list, fetches keyframes from Supabase,
    converts duration seconds → ms at THIS boundary only.
    """
    if not request.glosses:
        raise HTTPException(status_code=400, detail="Glosses list is empty")

    actions = [g.action.upper() for g in request.glosses]
    duration_map = {g.action.upper(): g.duration for g in request.glosses}

    # TODO: Replace mock with real Supabase query:
    # response = supabase.table("isl_glosses") \
    #     .select("*") \
    #     .in_("gloss", actions) \
    #     .execute()
    # rows = {row["gloss"]: row for row in response.data}

    # ── Mock Supabase data (remove when Supabase is configured) ──
    rows = _mock_supabase_rows(actions)

    sequence: List[EnrichedSign] = []
    for action in actions:
        row = rows.get(action)
        if row is None:
            # Fallback: neutral pose so animation never crashes
            row = _neutral_fallback(action)

        duration_s = duration_map[action]
        # ── DURATION CONVERSION: seconds → milliseconds ──
        # This is the ONLY place in the entire codebase where this conversion happens.
        duration_ms = int(duration_s * 1000)

        sequence.append(EnrichedSign(
            gloss=action,
            duration_ms=duration_ms,
            keyframes=row["keyframes"],
            nmm=row["nmm"],
        ))

    return EnrichResponse(sequence=sequence)


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _neutral_fallback(gloss: str) -> dict:
    """Returns a neutral pose when a gloss isn't found in Supabase."""
    return {
        "gloss": gloss,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 1.0, "RightHand": [0, 0, 0]},
        ],
        "nmm": {"face": "neutral"},
    }


def _mock_supabase_rows(actions: List[str]) -> dict:
    """
    Mock data — replace with real Supabase query when .env is configured.
    Mirrors exact structure of isl_glosses table rows.
    """
    mock = {
        "LIFE": {
            "keyframes": [
                {"time": 0.0, "RightHand": [0, 0, 0]},
                {"time": 0.7, "RightHand": [0.5, 1.0, 0]},
                {"time": 1.5, "RightHand": [1.0, 1.2, 0]},
            ],
            "nmm": {"face": "serious", "head": "neutral"},
        },
        "MY": {
            "keyframes": [
                {"time": 0.0, "RightHand": [0, 0, 0]},
                {"time": 0.5, "RightHand": [0.2, 0.8, 0]},
            ],
            "nmm": {"face": "neutral"},
        },
        "DANGER": {
            "keyframes": [
                {"time": 0.0, "RightHand": [0, 0, 0]},
                {"time": 1.0, "RightHand": [0.8, 1.5, 0.3]},
                {"time": 2.0, "RightHand": [1.2, 0.5, 0.6]},
            ],
            "nmm": {"face": "alert", "head": "forward"},
        },
        "HELP": {
            "keyframes": [
                {"time": 0.0, "RightHand": [0, 0, 0], "LeftHand": [0, 0, 0]},
                {"time": 0.9, "RightHand": [0.3, 1.2, 0], "LeftHand": [0.1, 0.8, 0]},
                {"time": 1.8, "RightHand": [0.5, 0.9, 0], "LeftHand": [0.2, 0.6, 0]},
            ],
            "nmm": {"face": "serious", "head": "neutral"},
        },
        "NAME": {
            "keyframes": [
                {"time": 0.0, "RightHand": [0, 0, 0]},
                {"time": 0.6, "RightHand": [0.1, 0.4, 0.2]},
                {"time": 1.2, "RightHand": [0.2, 0.6, 0.1]},
            ],
            "nmm": {"face": "neutral"},
        },
    }
    return {a: mock[a] for a in actions if a in mock}
