# Build stage
FROM maven:3.9.4-eclipse-temurin-21-alpine AS build
WORKDIR /app

# Copy only the necessary files for dependency resolution first
COPY pom.xml . 
# Pre-download dependencies to speed up builds and leverage caching
RUN mvn dependency:go-offline -B 

# Copy the rest of the application source
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Run stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copy the built JAR from the build stage
COPY --from=build /app/target/*.jar app.jar

# Expose application port
EXPOSE 5050

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]