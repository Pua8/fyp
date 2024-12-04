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
from MAR import mouth_aspect_ratio
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
EYE_AR_THRESH = 0.18
MOUTH_AR_THRESH = 0.65

# Define timers for eye and mouth
eye_start_time = None
mouth_start_time = None

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

    for rect in rects:
        shape = predictor(gray, rect)
        shape = face_utils.shape_to_np(shape)

        # Eye Aspect Ratio (EAR)
        (lStart, lEnd) = face_utils.FACIAL_LANDMARKS_IDXS["left_eye"]
        (rStart, rEnd) = face_utils.FACIAL_LANDMARKS_IDXS["right_eye"]
        leftEye = shape[lStart:lEnd]
        rightEye = shape[rStart:rEnd]
        leftEAR = eye_aspect_ratio(leftEye)
        rightEAR = eye_aspect_ratio(rightEye)
        ear = (leftEAR + rightEAR) / 2.0

        # Check if EAR is below threshold indicating closed eyes
        if ear < EYE_AR_THRESH:
            if eye_start_time is None:
                eye_start_time = time.time()
            else:
                duration = time.time() - eye_start_time
                if duration >= 3:  # 3 seconds of eye closure
                    return True  # Drowsiness detected due to eyes
        else:
            eye_start_time = None  # Reset if eyes are open

        # Mouth Aspect Ratio (MAR)
        (mStart, mEnd) = (49, 68)
        mouth = shape[mStart:mEnd]
        mar = mouth_aspect_ratio(mouth)

        if mar > MOUTH_AR_THRESH:
            if mouth_start_time is None:
                mouth_start_time = time.time()
            else:
                duration = time.time() - mouth_start_time
                if duration >= 1:  # 1 second of yawning
                    return True  # Drowsiness detected due to yawning
        else:
            mouth_start_time = None  # Reset if mouth is closed

    return False  # No drowsiness detected


# Endpoint to handle drowsiness detection
@app.post("/detect_drowsiness")
@app.post("/detect_drowsiness/")
async def detect_drowsiness(file: UploadFile = File(...)):
    try:
        # Read image data from incoming request
        image_data = await file.read()
        image = Image.open(io.BytesIO(image_data))

        # Detect drowsiness
        drowsiness_detected = detect_drowsiness_in_image(image)

        return JSONResponse(content={"alert_triggered": drowsiness_detected})

    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)


# Main entry point (if needed for standalone server)
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
