ARG BASE_ID

FROM builder:${BASE_ID}
ARG REVISION
ARG DEPTRACK_PROJECT_NAME
ARG DEPTRACK_MAVEN_GOAL
ARG DEPTRACK_HOST_URL
ARG DEPTRACK_APIKEY
RUN mvn --batch-mode ${DEPTRACK_MAVEN_GOAL} && \
      BOM_VALUE=$(cat ./target/bom.xml |base64 -w 0 -) && \
      rm -f target/payload.json && \
      echo -n "{\"projectName\": \"${DEPTRACK_PROJECT_NAME}\",\"projectVersion\": \"${REVISION}\",\"autoCreate\": true, \"bom\": \"${BOM_VALUE}\"}" > target/payload.json && \
      curl -v -X "PUT" "${DEPTRACK_HOST_URL}/api/v1/bom" \
       -H "Content-Type: application/json" \
       -H "X-API-Key: ${DEPTRACK_APIKEY}" \
       -d @target/payload.json