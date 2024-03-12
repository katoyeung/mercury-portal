# Use an Alpine base image
FROM alpine:latest as builder

# Install build dependencies, including git
RUN apk add --no-cache perl pcre-dev openssl-dev gcc libc-dev make zlib-dev linux-headers curl git

# Set environment variables for OpenResty version
ENV OPENRESTY_VERSION=1.25.3.1

# Download and unpack OpenResty
RUN curl -fSL https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz | tar xz

# Clone the nginx-module-vts repository
RUN git clone https://github.com/vozlt/nginx-module-vts.git

# Compile OpenResty with the VTS module
RUN cd /openresty-${OPENRESTY_VERSION} && \
    ./configure --add-module=../nginx-module-vts --with-http_ssl_module && \
    make && make install

# Start from the OpenResty image
FROM openresty/openresty:alpine

# Copy the compiled OpenResty from the builder stage
COPY --from=builder /usr/local/openresty /usr/local/openresty

# Install runtime libraries
RUN apk add --no-cache pcre openssl zlib

# Expose ports if needed
EXPOSE 80 443

# Copy the scripts into the container
COPY ./setup-script.sh /usr/local/bin/setup-script.sh
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

# Make the scripts executable
RUN chmod +x /usr/local/bin/setup-script.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
