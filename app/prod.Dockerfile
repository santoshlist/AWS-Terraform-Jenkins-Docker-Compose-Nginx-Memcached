FROM openjdk:8-jre-alpine3.9
COPY /target /app
COPY application.properties /app/application.properties
WORKDIR /app
ENTRYPOINT ["java", "-jar", "embedash-1.1-SNAPSHOT.jar", "--spring.config.location=./application.properties"]