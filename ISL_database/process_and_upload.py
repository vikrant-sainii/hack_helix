import os
import cv2
import mediapipe as mp
from supabase import create_client, Client
from dotenv import load_dotenv

# 1. Load Environment Variables
load_dotenv()
url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(url, key)

# 2. Define your vocabulary list (matches the downloaded file names)
vocab_list = ["BLOOD", "DOCTOR", "HOSPITAL"]

VIDEO_DIR = "./videos"
os.makedirs(VIDEO_DIR, exist_ok=True)

# Initialize MediaPipe Holistic
mp_holistic = mp.solutions.holistic

def extract_3d_keyframes_and_upload(word, filepath):
    print(f"Extracting 3D keyframes for: {word}")
    cap = cv2.VideoCapture(filepath)
    fps = cap.get(cv2.CAP_PROP_FPS)
    
    mp_drawing = mp.solutions.drawing_utils
    mp_drawing_styles = mp.solutions.drawing_styles
    
    keyframes = []
    frame_count = 0
    
    with mp_holistic.Holistic(min_detection_confidence=0.5, min_tracking_confidence=0.5) as holistic:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
                
            # Process the frame
            image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = holistic.process(image_rgb)
            
            # Draw the skeleton on the video ---
            mp_drawing.draw_landmarks(
                frame, results.right_hand_landmarks, mp_holistic.HAND_CONNECTIONS)
            mp_drawing.draw_landmarks(
                frame, results.left_hand_landmarks, mp_holistic.HAND_CONNECTIONS)
            
            # Show the video window!
            cv2.imshow(f'MediaPipe Tracking - {word}', frame)
            if cv2.waitKey(1) & 0xFF == ord('q'): # Press 'q' to skip video
                break

            fps_val = fps if fps > 0 else 30.0
            current_time = round(frame_count / fps_val, 3)
            frame_data = {"time": current_time}
            
            # Right Hand
            if results.right_hand_landmarks:
                wrist = results.right_hand_landmarks.landmark[0]
                frame_data["RightHand"] = [round(wrist.x, 3), round(wrist.y, 3), round(wrist.z, 3)]
            else:
                 frame_data["RightHand"] = [0, 0, 0]

            # Left Hand
            if results.left_hand_landmarks:
                wrist = results.left_hand_landmarks.landmark[0]
                frame_data["LeftHand"] = [round(wrist.x, 3), round(wrist.y, 3), round(wrist.z, 3)]
            else:
                 frame_data["LeftHand"] = [0, 0, 0]
                 
            keyframes.append(frame_data)
            frame_count += 1
            
    cap.release()
    cv2.destroyAllWindows()
    
    # Calculate true duration
    total_duration = round(frame_count / fps_val, 2)
    
    # Structure the payload exactly like your Supabase Schema
    db_record = {
        "gloss": word,
        "duration": total_duration,
        "keyframes": keyframes,
        "nmm": {
            "face": "serious", 
            "head": "neutral"
        }
    }
    
    print(f"Uploading {word} to Supabase... (Duration: {total_duration}s)")
    try:
        supabase.table('isl_glosses').upsert(db_record, on_conflict='gloss').execute()
        print(f" {word} uploaded successfully!\n")
    except Exception as e:
        print(f" Failed to upload {word}: {e}\n")


# 3. Execute the Pipeline on Local Files
print(" Starting local video processing...")
for word in vocab_list:
    video_path = os.path.join(VIDEO_DIR, f"{word}.mp4")
    
    # Verify the file actually exists before trying to run MediaPipe
    if os.path.exists(video_path):
        extract_3d_keyframes_and_upload(word, video_path)
    else:
        print(f" Skipping {word}: Could not find {video_path}")

print(" Pipeline Complete! Your Supabase database is ready.")