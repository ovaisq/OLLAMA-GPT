#!/usr/bin/env bash
# run service ©2025, Ovais Quraishi

SRVC_CONFIG_FILE=config_vals.txt

read_config(){
	local CONFIG_FILE="$1"
	if [[ -f ${CONFIG_FILE} ]]; then
		source ./${CONFIG_FILE}
	else
		echo "Unable to find ${CONFIG_FILE}. Exiting" >&2
		exit -1
	fi
}

read_config "${SRVC_CONFIG_FILE}"

# Check if SSL variables are set, and confirm that values assigned to them are
#	files that exist.
# If not, use default paths.
if [[ -n ${SSL_CERT} && -n ${SSL_KEY} ]]; then
    if [[ -f ${SSL_CERT} && -f ${SSL_KEY} ]]; then
        # Use the provided SSL certificates if they're valid.
        gunicorn ${SRVC_NAME}:app --certfile=${SSL_CERT} --keyfile=${SSL_KEY} \
            --bind ${SRVC_HOST_IP}:${SRVC_HOST_PORT} \
            --timeout ${SRVC_TIMEOUT} --workers ${SRVC_WORKERS} \
            --access-logfile zollama_access.log \
            --error-logfile zollama_error.log \
            --log-level ${SRVC_LOG_LEVEL}
    else
        # If SSL certificates are provided but not valid, inform the user.
        echo "SSL CERT/KEY ${SSL_CERT} and ${SSL_KEY} not found. Running unsecured HTTP"
        gunicorn ${SRVC_NAME}:app \
            --bind ${SRVC_HOST_IP}:${SRVC_HOST_PORT} \
            --timeout ${SRVC_TIMEOUT} --workers ${SRVC_WORKERS} \
            --access-logfile zollama_access.log \
            --error-logfile zollama_error.log \
            --log-level ${SRVC_LOG_LEVEL}
    fi
fi
