FROM python:3.11-slim
WORKDIR /app
COPY app.py .
COPY students.json .
RUN pip install --no-cache-dir flask requests python-jose cryptography
EXPOSE 8081
CMD ["python", "app.py"]