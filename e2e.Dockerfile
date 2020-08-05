FROM alpine:3.9
RUN apk update && apk add curl jq
COPY e2e.sh /e2e.sh
RUN chmod +X e2e.sh
CMD ["./e2e.sh"]
