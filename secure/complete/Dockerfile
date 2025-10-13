# Dockerfile đơn giản cho Spring Boot
FROM amazoncorretto:17

# Thiết lập working directory
WORKDIR /app

# Copy JAR file đã được build
COPY target/*.jar app.jar

# Expose port 8080
EXPOSE 8080

# Thiết lập JVM options
ENV JAVA_OPTS="-Xmx512m -Xms256m"

# Command để chạy ứng dụng
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]