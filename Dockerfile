# Use latest stable Dart image
FROM dart:stable

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Get dependencies
RUN dart pub get

# Compile server executable
RUN dart compile exe bin/main.dart -o bin/server

# Expose ports
EXPOSE 8080 8081 8082

# Run server
CMD ["bin/server"]
