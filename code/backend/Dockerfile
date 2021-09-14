FROM golang:alpine AS builder

# Set necessary environmet variables needed for our image
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# Move to working directory /build
WORKDIR /backend

# Copy the code into the container
COPY . .

# Build the application
RUN go mod init backend && go mod tidy && go build -o api

# Move to /dist directory as the place for resulting binary folder
WORKDIR /dist

# Copy binary from build to main folder
RUN cp /backend/api .

# Build a small image
FROM scratch

COPY --from=builder /dist/api /

# Command to run
ENTRYPOINT ["/api"]
