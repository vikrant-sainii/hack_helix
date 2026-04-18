"""
Seed script: populates isl_glosses table in Supabase with 20 core ISL signs.

Usage:
  1. Copy .env.template to .env and fill in credentials
  2. Run: python seed_glosses.py

Each sign has:
  - gloss: sign name (TEXT PRIMARY KEY)
  - duration: in SECONDS (float) — never stored as ms
  - keyframes: list of {time, BoneName: [x, y, z]} — Euler angles in radians
  - nmm: non-manual markers {face, head}
"""

import os
from dotenv import load_dotenv

load_dotenv()

# TODO: Uncomment when .env is configured
# from supabase import create_client
# supabase = create_client(
#     os.getenv("SUPABASE_URL", ""),
#     os.getenv("SUPABASE_ANON_KEY", ""),
# )

ISL_SIGNS = [
    {
        "gloss": "LIFE",
        "duration": 1.5,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 0.7, "RightHand": [0.5, 1.0, 0]},
            {"time": 1.5, "RightHand": [1.0, 1.2, 0]},
        ],
        "nmm": {"face": "serious", "head": "neutral"},
    },
    {
        "gloss": "MY",
        "duration": 1.0,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 0.5, "RightHand": [0.2, 0.8, 0]},
        ],
        "nmm": {"face": "neutral"},
    },
    {
        "gloss": "DANGER",
        "duration": 2.0,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 1.0, "RightHand": [0.8, 1.5, 0.3]},
            {"time": 2.0, "RightHand": [1.2, 0.5, 0.6]},
        ],
        "nmm": {"face": "alert", "head": "forward"},
    },
    {
        "gloss": "HELP",
        "duration": 1.8,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0], "LeftHand": [0, 0, 0]},
            {"time": 0.9, "RightHand": [0.3, 1.2, 0], "LeftHand": [0.1, 0.8, 0]},
            {"time": 1.8, "RightHand": [0.5, 0.9, 0], "LeftHand": [0.2, 0.6, 0]},
        ],
        "nmm": {"face": "serious", "head": "neutral"},
    },
    {
        "gloss": "NAME",
        "duration": 1.2,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 0.6, "RightHand": [0.1, 0.4, 0.2]},
            {"time": 1.2, "RightHand": [0.2, 0.6, 0.1]},
        ],
        "nmm": {"face": "neutral"},
    },
    {
        "gloss": "WATER",
        "duration": 1.3,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 0.65, "RightHand": [0.0, 0.5, 0.8]},
            {"time": 1.3, "RightHand": [0.1, 0.3, 0.6]},
        ],
        "nmm": {"face": "neutral"},
    },
    {
        "gloss": "FOOD",
        "duration": 1.1,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 0.55, "RightHand": [0.3, 0.9, 0.1]},
            {"time": 1.1, "RightHand": [0.4, 0.7, 0.0]},
        ],
        "nmm": {"face": "neutral"},
    },
    {
        "gloss": "GOOD",
        "duration": 0.8,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 0.8, "RightHand": [0.0, 0.0, 1.5]},
        ],
        "nmm": {"face": "happy", "head": "nod"},
    },
    {
        "gloss": "BAD",
        "duration": 0.8,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 0.8, "RightHand": [0.0, 0.0, -1.5]},
        ],
        "nmm": {"face": "serious"},
    },
    {
        "gloss": "THANK",
        "duration": 1.0,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0.3, 0]},
            {"time": 0.5, "RightHand": [0.2, 0.5, 0]},
            {"time": 1.0, "RightHand": [0.4, 0.1, 0]},
        ],
        "nmm": {"face": "happy", "head": "neutral"},
    },
    {
        "gloss": "PLEASE",
        "duration": 1.2,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 0.4, "RightHand": [0.5, 0.3, 0.2]},
            {"time": 0.8, "RightHand": [0.8, 0.1, 0.4]},
            {"time": 1.2, "RightHand": [0.5, 0.2, 0.1]},
        ],
        "nmm": {"face": "neutral"},
    },
    {
        "gloss": "SORRY",
        "duration": 1.5,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 0.5, "RightHand": [0.3, 0.5, 0.1]},
            {"time": 1.0, "RightHand": [0.6, 0.2, 0.3]},
            {"time": 1.5, "RightHand": [0.3, 0.4, 0.1]},
        ],
        "nmm": {"face": "serious", "head": "down"},
    },
    {
        "gloss": "YES",
        "duration": 0.6,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0.5, 0]},
            {"time": 0.3, "RightHand": [0, 0.8, 0]},
            {"time": 0.6, "RightHand": [0, 0.5, 0]},
        ],
        "nmm": {"face": "neutral", "head": "nod"},
    },
    {
        "gloss": "NO",
        "duration": 0.7,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, -0.3]},
            {"time": 0.35, "RightHand": [0, 0, 0.3]},
            {"time": 0.7, "RightHand": [0, 0, -0.1]},
        ],
        "nmm": {"face": "serious", "head": "shake"},
    },
    {
        "gloss": "COME",
        "duration": 1.0,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0.5]},
            {"time": 0.5, "RightHand": [0.2, 0.4, 0.3]},
            {"time": 1.0, "RightHand": [0.4, 0.2, 0.0]},
        ],
        "nmm": {"face": "neutral"},
    },
    {
        "gloss": "GO",
        "duration": 1.0,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 0.5, "RightHand": [0.3, 0.3, 0.4]},
            {"time": 1.0, "RightHand": [0.6, 0.1, 0.8]},
        ],
        "nmm": {"face": "neutral"},
    },
    {
        "gloss": "STOP",
        "duration": 0.8,
        "keyframes": [
            {"time": 0.0, "RightHand": [0, 0, 0]},
            {"time": 0.4, "RightHand": [0.0, 1.0, 0.0]},
            {"time": 0.8, "RightHand": [0.0, 1.0, 0.0]},
        ],
        "nmm": {"face": "alert"},
    },
    {
        "gloss": "MORE",
        "duration": 1.2,
        "keyframes": [
            {"time": 0.0, "RightHand": [0.2, 0.2, 0], "LeftHand": [-0.2, 0.2, 0]},
            {"time": 0.6, "RightHand": [0.5, 0.5, 0], "LeftHand": [-0.5, 0.5, 0]},
            {"time": 1.2, "RightHand": [0.2, 0.2, 0], "LeftHand": [-0.2, 0.2, 0]},
        ],
        "nmm": {"face": "neutral"},
    },
    {
        "gloss": "LESS",
        "duration": 1.0,
        "keyframes": [
            {"time": 0.0, "RightHand": [0.5, 0.3, 0], "LeftHand": [-0.5, 0.3, 0]},
            {"time": 0.5, "RightHand": [0.2, 0.1, 0], "LeftHand": [-0.2, 0.1, 0]},
            {"time": 1.0, "RightHand": [0.1, 0.0, 0], "LeftHand": [-0.1, 0.0, 0]},
        ],
        "nmm": {"face": "neutral"},
    },
    {
        "gloss": "UNDERSTAND",
        "duration": 1.5,
        "keyframes": [
            {"time": 0.0, "RightHand": [0.1, 0.8, 0.0]},
            {"time": 0.5, "RightHand": [0.2, 1.0, 0.1]},
            {"time": 1.0, "RightHand": [0.4, 1.2, 0.3]},
            {"time": 1.5, "RightHand": [0.6, 0.9, 0.5]},
        ],
        "nmm": {"face": "neutral", "head": "nod"},
    },
]


def seed():
    print(f"Seeding {len(ISL_SIGNS)} ISL signs...")
    for sign in ISL_SIGNS:
        # TODO: Uncomment when Supabase is configured:
        # result = supabase.table("isl_glosses").upsert(sign).execute()
        # print(f"  ✓ {sign['gloss']} (duration: {sign['duration']}s)")
        print(f"  [DRY RUN] Would seed: {sign['gloss']} (duration: {sign['duration']}s)")
    print("Done. (Connect Supabase to actually insert rows.)")


if __name__ == "__main__":
    seed()
