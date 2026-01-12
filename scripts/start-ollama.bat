@echo off
REM Start Ollama with OLLAMA_ORIGINS environment variable
SET OLLAMA_ORIGINS=*
"C:\Users\%USERNAME%\AppData\Local\Programs\Ollama\ollama.exe" serve
