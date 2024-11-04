from scipy.spatial import distance as dist
from imutils.video import VideoStream
from imutils import face_utils
import imutils
import time
import dlib
import cv2
import numpy as np
from EAR import eye_aspect_ratio
from MAR import mouth_aspect_ratio
from HeadPose import getHeadTiltAndCoords

# Initialize dlib's face detector (HOG-based) and then create the
# facial landmark predictor
print("[INFO] loading facial landmark predictor...")
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor('shape_predictor_68_face_landmarks.dat')

# Initialize the video stream and sleep for a bit, allowing the
# camera sensor to warm up
print("[INFO] initializing camera...")
vs = VideoStream(src=0).start()
time.sleep(2.0)

# 400x225 to 1024x576
frame_width = 1024
frame_height = 576


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


def process_eyes(frame, shape):
    (lStart, lEnd) = face_utils.FACIAL_LANDMARKS_IDXS["left_eye"]
    (rStart, rEnd) = face_utils.FACIAL_LANDMARKS_IDXS["right_eye"]

    leftEye = shape[lStart:lEnd]
    rightEye = shape[rStart:rEnd]
    leftEAR = eye_aspect_ratio(leftEye)
    rightEAR = eye_aspect_ratio(rightEye)
    ear = (leftEAR + rightEAR) / 2.0

    leftEyeHull = cv2.convexHull(leftEye)
    rightEyeHull = cv2.convexHull(rightEye)
    cv2.drawContours(frame, [leftEyeHull], -1, (0, 255, 0), 1)
    cv2.drawContours(frame, [rightEyeHull], -1, (0, 255, 0), 1)


def process_mouth(frame, shape):
    (mStart, mEnd) = (49, 68)
    mouth = shape[mStart:mEnd]
    mar = mouth_aspect_ratio(mouth)
    mouthHull = cv2.convexHull(mouth)
    cv2.drawContours(frame, [mouthHull], -1, (0, 255, 0), 1)


def capture_state(message, duration=10):
    print(message)
    input("[INFO] Press Enter to start capturing...")
    end_time = time.time() + duration

    ear_values = []
    mar_values = []

    while time.time() < end_time:
        frame = vs.read()
        frame = imutils.resize(frame, width=frame_width, height=frame_height)
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        frame = process_frame(frame, gray, detector, predictor)

        cv2.putText(frame, message, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
        cv2.imshow("Frame", frame)
        key = cv2.waitKey(1) & 0xFF

        if key == ord("q"):
            break

    avg_ear = np.mean(ear_values)
    avg_mar = np.mean(mar_values)

    return avg_ear, avg_mar


def capture_thresholds():
    eye_open, mouth_closed = capture_state("[INFO] Please keep your eyes open and mouth closed for 10 seconds.")
    eye_closed, mouth_closed_2 = capture_state("[INFO] Please keep your eyes closed and mouth closed for 10 seconds.")
    eye_open_2, mouth_open = capture_state("[INFO] Please keep your eyes open and mouth open for 10 seconds.")

    eye_ar_thresh = (eye_open + eye_closed) / 2.0
    mouth_ar_thresh = (mouth_open + mouth_closed) / 2.0

    return eye_ar_thresh, mouth_ar_thresh


def main():
    eye_ar_thresh, mouth_ar_thresh = capture_thresholds()
    print("[INFO] Eye aspect ratio threshold: {:.2f}".format(eye_ar_thresh))
    print("[INFO] Mouth aspect ratio threshold: {:.2f}".format(mouth_ar_thresh))

    cv2.destroyAllWindows()
    vs.stop()


if __name__ == "__main__":
    main()
