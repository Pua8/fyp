#!/usr/bin/env python
from scipy.spatial import distance as dist
from imutils.video import VideoStream
from imutils import face_utils
import argparse
import imutils
import time
import dlib
import math
import cv2
import numpy as np
from EAR import eye_aspect_ratio
from MAR import mouth_aspect_ratio
from HeadPose import getHeadTiltAndCoords
import os
import pygame

def initialize_detector():
    print("[INFO] loading facial landmark predictor...")
    detector = dlib.get_frontal_face_detector()
    predictor = dlib.shape_predictor('shape_predictor_68_face_landmarks.dat')
    return detector, predictor

# Initialize pygame mixer explicitly
def initialize_mixer():
    try:
        pygame.mixer.quit()  # Ensure no previous mixer is running
        pygame.mixer.init(frequency=44100, size=-16, channels=2, buffer=512)
        print("[INFO] Mixer initialized successfully.")
    except Exception as e:
        print(f"[ERROR] Unable to initialize mixer: {e}")
        raise


def initialize_camera():
    print("[INFO] initializing camera...")
    vs = VideoStream(src=0).start()
    time.sleep(2.0)
    return vs


def process_frame(frame, gray, detector, predictor):
    rects = detector(gray, 0)
    if len(rects) > 0:
        text = "{} face(s) found".format(len(rects))
        cv2.putText(frame, text, (10, 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)

    for rect in rects:
        (bX, bY, bW, bH) = face_utils.rect_to_bb(rect)
        cv2.rectangle(frame, (bX, bY), (bX + bW, bY + bH), (0, 255, 0), 1)
        shape = predictor(gray, rect)
        shape = face_utils.shape_to_np(shape)

        process_landmarks(frame, shape)
        process_eyes(frame, shape)
        process_mouth(frame, shape)
        process_head_pose(frame, shape, frame.shape)

    return frame


def process_landmarks(frame, shape):
    image_points = np.zeros((6, 2), dtype="double")
    for (i, (x, y)) in enumerate(shape):
        if i in [33, 8, 36, 45, 48, 54]:
            idx = [33, 8, 36, 45, 48, 54].index(i)
            image_points[idx] = (x, y)
            color = (0, 255, 0)
        else:
            color = (0, 0, 255)
        cv2.circle(frame, (x, y), 1, color, -1)
        cv2.putText(frame, str(i + 1), (x - 10, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.35, color, 1)

    for p in image_points:
        cv2.circle(frame, (int(p[0]), int(p[1])), 3, (0, 0, 255), -1)

    (head_tilt_degree, start_point, end_point, end_point_alt) = getHeadTiltAndCoords(frame.shape, image_points,
                                                                                     frame.shape[0])
    cv2.line(frame, start_point, end_point, (255, 0, 0), 2)
    cv2.line(frame, start_point, end_point_alt, (0, 0, 255), 2)

    if head_tilt_degree:
        cv2.putText(frame, 'Head Tilt Degree: ' + str(head_tilt_degree[0]), (170, 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5,
                    (0, 0, 255), 2)


from playsound import playsound  # Import playsound for playing audio
import time  # For time tracking

# Initialize global variables
start_time = None  # Start time for when eyes are detected as closed
alert_triggered = False  # Flag to avoid repeated alerts

def process_eyes(frame, shape):
    global COUNTER, start_time, alert_triggered

    (lStart, lEnd) = face_utils.FACIAL_LANDMARKS_IDXS["left_eye"]
    (rStart, rEnd) = face_utils.FACIAL_LANDMARKS_IDXS["right_eye"]

    leftEye = shape[lStart:lEnd]
    rightEye = shape[rStart:rEnd]
    leftEAR = eye_aspect_ratio(leftEye)
    rightEAR = eye_aspect_ratio(rightEye)
    ear = (leftEAR + rightEAR) / 2.0

    # Draw eye contours
    leftEyeHull = cv2.convexHull(leftEye)
    rightEyeHull = cv2.convexHull(rightEye)
    cv2.drawContours(frame, [leftEyeHull], -1, (0, 255, 0), 1)
    cv2.drawContours(frame, [rightEyeHull], -1, (0, 255, 0), 1)

    # Display EAR value
    cv2.putText(frame, "EAR: {:.2f}".format(ear), (850, 20), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

    # Check if EAR is below the threshold
    if ear < EYE_AR_THRESH:
        cv2.putText(frame, "Eyes Closed!", (10, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

        if start_time is None:  # First time eyes are detected as closed
            start_time = time.time()  # Record start time
        else:
            # Calculate how long the eyes have been closed
            duration = time.time() - start_time
            if duration >= 3:  # If eyes are closed for >= 3 seconds
                if not alert_triggered:
                    alert_triggered = True  # Avoid re-triggering alert
                    cv2.putText(frame, "Drowsy! Alert Triggered!", (500, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                    # Play alert sound
                    sound_path = os.path.join("Sound", "AlertSound.wav")
                    play_alert_sound(sound_path)
    else:
        # Reset variables if eyes are open
        start_time = None
        alert_triggered = False
        COUNTER = 0


def process_mouth(frame, shape):
    global start_time, alert_triggered

    (mStart, mEnd) = (49, 68)
    mouth = shape[mStart:mEnd]
    mar = mouth_aspect_ratio(mouth)

    mouthHull = cv2.convexHull(mouth)
    cv2.drawContours(frame, [mouthHull], -1, (0, 255, 0), 1)
    cv2.putText(frame, "MAR: {:.2f}".format(mar), (650, 20), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

    # If the mouth is open (MAR > threshold), check the duration
    if mar > MOUTH_AR_THRESH:
        cv2.putText(frame, "Mouth Open!", (250, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

        if start_time is None:  # Record the start time when the mouth first opens
            start_time = time.time()
            #print("Start time recorded!")  # Debug: check if start time is recorded
        else:
            # Calculate how long the mouth has been open
            duration = time.time() - start_time
            #print(f"Duration: {duration} seconds")  # Debug: check duration

            if duration >= 1:
                if not alert_triggered:
                    alert_triggered = True  # Trigger the alert sound only once
                    cv2.putText(frame, "Yawning! Alert Triggered!", (800, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.7,
                                (0, 0, 255), 2)
                    # Play alert sound
                    sound_path = os.path.join("Sound", "AlertSound.wav")
                    play_alert_sound(sound_path)
    else:
        # If the mouth is closed, reset the timer
        #if start_time is not None:
            #print("Mouth closed, resetting timer")  # Debug: check if timer is being reset
        start_time = None
        alert_triggered = False


def process_head_pose(frame, shape, frame_shape):
    size = frame_shape
    image_points = np.array([
        shape[33],  # Nose tip
        shape[8],   # Chin
        shape[36],  # Left eye left corner
        shape[45],  # Right eye right corner
        shape[48],  # Left mouth corner
        shape[54]   # Right mouth corner
    ], dtype="double")

def main():
    detector, predictor = initialize_detector()
    vs = initialize_camera()

    while True:
        frame = vs.read()
        if frame is None:
            print("[ERROR] Unable to read from camera. Exiting...")
            break

        frame = imutils.resize(frame, width=frame_width, height=frame_height)
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        frame = process_frame(frame, gray, detector, predictor)

        cv2.imshow("Frame", frame)
        key = cv2.waitKey(1) & 0xFF

        if key == ord("q"):
            break

    cv2.destroyAllWindows()
    vs.stop()

def play_alert_sound(file_path):
    """Play an alert sound when drowsiness is detected."""
    try:
        # Reinitialize mixer before playback
        if not pygame.mixer.get_init():
            initialize_mixer()

        pygame.mixer.music.load(file_path)  # Load the MP3 file
        pygame.mixer.music.play()  # Play the sound
        while pygame.mixer.music.get_busy():  # Wait until the sound finishes
            time.sleep(0.1)
    except Exception as e:
        print(f"[ERROR] Unable to play sound: {e}")

if __name__ == "__main__":
    EYE_AR_THRESH = 0.18
    MOUTH_AR_THRESH = 0.65
    EYE_AR_CONSEC_FRAMES = 3
    COUNTER = 0
    frame_width = 1024
    frame_height = 576

    main()

