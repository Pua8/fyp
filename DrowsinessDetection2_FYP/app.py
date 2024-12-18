from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import io
import cv2
import numpy as np
import dlib
from imutils import face_utils
from EAR import eye_aspect_ratio
from MOR import mouth_opening_ratio
import time

# Initialize the FastAPI app
app = FastAPI()

# Add CORS middleware to allow requests from frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["POST", "GET", "OPTIONS"],
    allow_headers=["*"],
)

# Load dlib's face detector and facial landmark predictor
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor('shape_predictor_68_face_landmarks.dat')

# Define global thresholds
EYE_AR_THRESH = 0.23
MOUTH_AR_THRESH = 0.65

# Define timers for eye and mouth detection
eye_start_time = None  # Timer for eyes closed detection
mouth_start_time = None  # Timer for mouth open detection

# Helper function for detecting drowsiness in the frame
def detect_drowsiness_in_image(image: Image):
    global eye_start_time, mouth_start_time

    # Convert PIL Image to OpenCV format (numpy array)
    frame = np.array(image)
    frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)  # Convert from RGB to BGR

    # Convert frame to grayscale
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Detect faces
    rects = detector(gray, 0)

    # Initialize flags for detecting drowsiness causes
    eyes_closed_detected = False
    mouth_open_detected = False

    for rect in rects:
        shape = predictor(gray, rect)
        shape = face_utils.shape_to_np(shape)

        # Eye Aspect Ratio (EAR) for closed eyes detection
        (lStart, lEnd) = face_utils.FACIAL_LANDMARKS_IDXS["left_eye"]
        (rStart, rEnd) = face_utils.FACIAL_LANDMARKS_IDXS["right_eye"]
        leftEye = shape[lStart:lEnd]
        rightEye = shape[rStart:rEnd]
        leftEAR = eye_aspect_ratio(leftEye)
        rightEAR = eye_aspect_ratio(rightEye)
        ear = (leftEAR + rightEAR) / 2.0

        # Detect if eyes are closed for a certain duration
        if ear <= EYE_AR_THRESH:
            if eye_start_time is None:
                eye_start_time = time.time()
            else:
                duration = time.time() - eye_start_time
                if duration >= 2:  # Eyes closed for 2 seconds
                    eyes_closed_detected = True
        else:
            eye_start_time = None  # Reset timer if eyes are open

        # Mouth Opening Ratio (MOR) for yawning detection
        (mStart, mEnd) = (49, 68)  # Indices for mouth landmarks
        mouth = shape[mStart:mEnd]
        mor = mouth_opening_ratio(mouth)

        # Detect if mouth is open for a certain duration
        if mor > MOUTH_AR_THRESH:
            if mouth_start_time is None:
                mouth_start_time = time.time()
            else:
                duration = time.time() - mouth_start_time
                if duration >= 2:  # Mouth open for 2 seconds
                    mouth_open_detected = True
        else:
            mouth_start_time = None  # Reset timer if mouth is closed

    # Determine if alert is triggered by either or both conditions
    alert_triggered = eyes_closed_detected or mouth_open_detected

    return {
        "alert_triggered": alert_triggered,
        "eyes_closed": eyes_closed_detected,
        "mouth_open": mouth_open_detected,
    }


# Endpoint to handle drowsiness detection
@app.post("/detect_drowsiness")
@app.post("/detect_drowsiness/")
async def detect_drowsiness(file: UploadFile = File(...)):
    try:
        # Read image data from incoming request
        image_data = await file.read()
        image = Image.open(io.BytesIO(image_data))

        # Detect drowsiness
        result = detect_drowsiness_in_image(image)

        # Return detailed response
        return JSONResponse(content=result)

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


# Main entry point (if needed for standalone server)
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
