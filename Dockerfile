# Use Debian Bookworm as the base image ©2025, Ovais Quraishi
FROM python:3.9-slim

WORKDIR /app

# Debian 12 thing
ENV PIP_BREAK_SYSTEM_PACKAGES 1

# Copy necessary files to /app directory
COPY requirements.txt /app/
COPY *.pem /app/
COPY *.TXT /app/
COPY text_encryption.key /app/

COPY zollama.py /app/
COPY gptutils.py /app/
COPY encryption.py /app/
COPY clincodeutils.py /app/

COPY run_srvc.sh /app/

RUN pip3 install --uprgade -r /app/requirements.txt

# Expose port 5009
EXPOSE 5009

# ZOllama Env vars
ARG host
ENV host $host
ARG port
ENV port $port
ARG database
ENV database $database
ARG user
ENV user $user
ARG password
ENV password $password
ARG JWT_SECRET_KEY
ENV JWT_SECRET_KEY $JWT_SECRET_KEY
ARG SRVC_SHARED_SECRET
ENV SRVC_SHARED_SECRET $SRVC_SHARED_SECRET
ARG IDENTITY
ENV IDENTITY $IDENTITY
ARG APP_SECRET_KEY
ENV APP_SECRET_KEY $APP_SECRET_KEY
ARG CSRF_PROTECTION_KEY
ENV CSRF_PROTECTION_KEY $CSRF_PROTECTION_KEY
ARG ENDPOINT_URL
ENV ENDPOINT_URL $ENDPOINT_URL 
ARG OLLAMA_API_URL
ENV OLLAMA_API_URL $OLLAMA_API_URL
ARG PROC_WORKERS
ENV PROC_WORKERS $PROC_WORKERS
ARG LLMS
ENV LLMS $LLMS
ARG MEDLLMS
ENV MEDLLMS $MEDLLMS
ARG ENCRYPTION_KEY
ENV ENCRYPTION_KEY $ENCRYPTION_KEY
ARG SRVC_NAME
ENV SRVC_NAME $SRVC_NAME
ARG SSL_CERT
ENV SSL_CERT ${SSL_CERT}
ARG SSL_KEY
ENV SSL_KEY ${SSL_KEY}

# Run ZOllama Run!
CMD ["/app/run_srvc.sh"]
