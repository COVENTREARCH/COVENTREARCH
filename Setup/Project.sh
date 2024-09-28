#!/bin/bash

# Set project variables
PROJECT_NAME="youtube_openai_integration"
PYTHON_VERSION="python3" # Change to your Python version, e.g., python3.9
YOUTUBE_API_KEY=""
OPENAI_API_KEY=""

# Create a new directory for the project
echo "Creating project directory..."
mkdir $PROJECT_NAME && cd $PROJECT_NAME

# Initialize Git repository
echo "Initializing Git repository..."
git init

# Create the project structure
echo "Creating project structure..."
mkdir -p config venv
touch main.py requirements.txt .gitignore README.md config/config.yaml

# Add code to main.py
cat <<EOL > main.py
from fastapi import FastAPI, HTTPException
import requests
import openai

app = FastAPI()

# Load API keys from config file
import yaml
with open('config/config.yaml', 'r') as file:
    config = yaml.safe_load(file)
YOUTUBE_API_KEY = config['YOUTUBE_API_KEY']
OPENAI_API_KEY = config['OPENAI_API_KEY']
openai.api_key = OPENAI_API_KEY

def get_youtube_data(query):
    url = f"https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=5&q={query}&key={YOUTUBE_API_KEY}"
    response = requests.get(url)
    if response.status_code != 200:
        raise HTTPException(status_code=400, detail="Error fetching YouTube data")
    return response.json()

@app.get("/youtube/{query}")
async def search_youtube(query: str):
    data = get_youtube_data(query)
    return data

@app.post("/process-openai")
async def process_openai(data: dict):
    prompt = data.get("prompt", "")
    try:
        response = openai.Completion.create(
            engine="text-davinci-004",
            prompt=prompt,
            max_tokens=100
        )
        return {"result": response.choices[0].text.strip()}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
EOL

# Create requirements.txt
echo "Creating requirements.txt..."
cat <<EOL > requirements.txt
fastapi
uvicorn
requests
openai
pyyaml
EOL

# Create .gitignore
echo "Creating .gitignore..."
cat <<EOL > .gitignore
venv/
__pycache__/
*.pyc
*.pyo
config/config.yaml
EOL

# Create README.md
echo "Creating README.md..."
cat <<EOL > README.md
# YouTube and OpenAI Integration API

This project provides an API that fetches data from YouTube and processes OpenAI completions.

## Setup

1. Clone the repository.
2. Create a virtual environment:
   \`\`\`
   python -m venv venv
   \`\`\`
3. Activate the virtual environment and install dependencies:
   \`\`\`
   pip install -r requirements.txt
   \`\`\`
4. Set your API keys in \`config/config.yaml\`.

## Running the Application

Start the FastAPI server:
\`\`\`
uvicorn main:app --reload
\`\`\`
Access the API at \`http://localhost:8000\`.
EOL

# Set up the Python environment
echo "Setting up Python virtual environment..."
$PYTHON_VERSION -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create the config.yaml file securely
echo "Creating encrypted config.yaml file..."
read -sp "Enter your YouTube API Key: " YOUTUBE_API_KEY
echo
read -sp "Enter your OpenAI API Key: " OPENAI_API_KEY
echo

cat <<EOL > config/config.yaml
YOUTUBE_API_KEY: "$YOUTUBE_API_KEY"
OPENAI_API_KEY: "$OPENAI_API_KEY"
EOL

# Encrypt the config.yaml file
echo "Encrypting config.yaml..."
openssl enc -aes-256-cbc -salt -in config/config.yaml -out config/config.yaml.enc -k "your_encryption_password"
rm config/config.yaml

# Generate SSH keys if not already present
echo "Generating SSH keys for secure access..."
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

# Display the SSH public key
echo "Your SSH public key is:"
cat ~/.ssh/id_rsa.pub

echo "Setup complete. Remember to configure your server to accept the SSH key for secure access."
