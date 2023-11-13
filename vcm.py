import speech_recognition as sr
import subprocess

# Initialize the recognizer
r = sr.Recognizer()

# Capture voice input from the microphone
def capture_voice_input():
    with sr.Microphone() as source:
        print("Listening...")
        audio = r.listen(source)

    try:
        # Use Google Speech Recognition to transcribe the audio
        text = r.recognize_google(audio)
        return text
    except sr.UnknownValueError:
        print("Could not understand audio")
        return ""
    except sr.RequestError as e:
        print("Error: {0}".format(e))
        return ""

# Execute the command based on voice input
def execute_command(command):
    try:
        subprocess.run(command, shell=True)
    except Exception as e:
        print("Error executing command: {0}".format(e))

# Main program loop
while True:
    # Capture voice input
    command = capture_voice_input()
    
    # Check if voice input is not empty
    if command:
        print("Command: {0}".format(command))
        
        # Check for specific keywords in the command
        if "scan" in command:
            print("Starting scanner...")
            # Execute your scanner bash script or relevant commands here
            execute_command("bash mk_3.sh")
        elif "exit" in command:
            print("Exiting...")
            break
        else:
            print("Unknown command")

