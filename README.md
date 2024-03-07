# Mercury Portal

## Key Features

- **Nginx & OpenResty**: Leverages the high performance and flexibility of Nginx and OpenResty for web serving and proxying capabilities.
- **JWT Authentication Supported**: Implements JSON Web Token (JWT) for secure and scalable user authentication.
- **API Tokens Management**: Provides robust management features for API tokens, enhancing security and ease of access control.
- **MVC Structure**: Utilizes the Model-View-Controller (MVC) architectural pattern, facilitating organized and efficient application development.
- **Decoupled Configuration**: Designed to be decoupled from other Nginx configurations, ensuring modular and clean setup.
- **Flexible Access Guard**: Offers flexible options to use the access guard for upstream applications, providing an additional layer of security.

## Setup

### Generate JWT Secret Key

Securely generate a JWT secret key using OpenSSL:

```bash
openssl rand -base64 32
```

### Start the Application

Use Docker Compose to start the application services:

```bash
docker-compose up -d --force-recreate
```

## Managing Users

### Testing Add User

To add a user to the system, you'll first need to generate a password hash. Use an online SHA256 hash generator for this purpose, such as [passwordsgenerator.net](https://passwordsgenerator.net/sha256-hash-generator).

```bash
# Access Redis CLI within the Docker container
docker exec -it redis redis-cli

# Add a user with a hashed password and an ID
HSET users:user password <hashed_password> id <user_id>

# Verify the user has been added
HGETALL users:user

# Delete the user (if needed)
DEL users:user

# Remove all users matching the pattern 'users:*'
redis-cli --scan --pattern 'users:*' | xargs redis-cli del
```

## Development

### Install Libraries

To add external Lua libraries as submodules:

```bash
git submodule add <repository-url> path/to/lua-libraries/library-name
git submodule update --remote --merge
```

Replace `<repository-url>` with the actual URL of the library's Git repository and `path/to/lua-libraries/library-name` with the desired local path.

## Testing

k6 run index_test.js

```
          /\      |‾‾| /‾‾/   /‾‾/
     /\  /  \     |  |/  /   /  /
    /  \/    \    |     (   /   ‾‾\
   /          \   |  |\  \ |  (‾)  |
  / __________ \  |__| \__\ \_____/ .io

     execution: local
        script: index_test.js
        output: -

     scenarios: (100.00%) 1 scenario, 100 max VUs, 1m30s max duration (incl. graceful stop):
              * default: 100 looping VUs for 1m0s (gracefulStop: 30s)


     ✓ is status 200

     checks.........................: 100.00% ✓ 2177210      ✗ 0
     data_received..................: 1.1 GB  18 MB/s
     data_sent......................: 163 MB  2.7 MB/s
     http_req_blocked...............: avg=3.58µs  min=0s       med=0s     max=58.4ms   p(90)=1µs    p(95)=1µs
     http_req_connecting............: avg=2.5µs   min=0s       med=0s     max=58.38ms  p(90)=0s     p(95)=0s
     http_req_duration..............: avg=2.71ms  min=90µs     med=2.28ms max=121.55ms p(90)=3.94ms p(95)=4.62ms
       { expected_response:true }...: avg=2.71ms  min=90µs     med=2.28ms max=121.55ms p(90)=3.94ms p(95)=4.62ms
     http_req_failed................: 0.00%   ✓ 0            ✗ 2177210
     http_req_receiving.............: avg=13.62µs min=4µs      med=6µs    max=115.81ms p(90)=15µs   p(95)=23µs
     http_req_sending...............: avg=4.39µs  min=1µs      med=2µs    max=55.27ms  p(90)=4µs    p(95)=6µs
     http_req_tls_handshaking.......: avg=0s      min=0s       med=0s     max=0s       p(90)=0s     p(95)=0s
     http_req_waiting...............: avg=2.69ms  min=72µs     med=2.26ms max=121.53ms p(90)=3.92ms p(95)=4.59ms
     http_reqs......................: 2177210 36285.730852/s
     iteration_duration.............: avg=2.75ms  min=110.04µs med=2.3ms  max=139.85ms p(90)=3.97ms p(95)=4.68ms
     iterations.....................: 2177210 36285.730852/s
     vus............................: 100     min=100        max=100
     vus_max........................: 100     min=100        max=100


running (1m00.0s), 000/100 VUs, 2177210 complete and 0 interrupted iterations
default ✓ [======================================] 100 VUs  1m0s
```

k6 run login_test.js

```
          /\      |‾‾| /‾‾/   /‾‾/
     /\  /  \     |  |/  /   /  /
    /  \/    \    |     (   /   ‾‾\
   /          \   |  |\  \ |  (‾)  |
  / __________ \  |__| \__\ \_____/ .io

     execution: local
        script: tests/login_test.js
        output: -

     scenarios: (100.00%) 1 scenario, 100 max VUs, 1m30s max duration (incl. graceful stop):
              * default: 100 looping VUs for 1m0s (gracefulStop: 30s)


     ✓ is status 200

     checks.........................: 100.00% ✓ 1070002      ✗ 0
     data_received..................: 812 MB  14 MB/s
     data_sent......................: 186 MB  3.1 MB/s
     http_req_blocked...............: avg=2.55µs  min=0s       med=0s     max=18.84ms  p(90)=1µs    p(95)=2µs
     http_req_connecting............: avg=1.66µs  min=0s       med=0s     max=18.82ms  p(90)=0s     p(95)=0s
     http_req_duration..............: avg=5.57ms  min=193µs    med=4.74ms max=150.04ms p(90)=8.73ms p(95)=10.84ms
       { expected_response:true }...: avg=5.57ms  min=193µs    med=4.74ms max=150.04ms p(90)=8.73ms p(95)=10.84ms
     http_req_failed................: 0.00%   ✓ 0            ✗ 1070002
     http_req_receiving.............: avg=12.48µs min=4µs      med=8µs    max=43.37ms  p(90)=17µs   p(95)=28µs
     http_req_sending...............: avg=3.81µs  min=1µs      med=2µs    max=13.8ms   p(90)=6µs    p(95)=9µs
     http_req_tls_handshaking.......: avg=0s      min=0s       med=0s     max=0s       p(90)=0s     p(95)=0s
     http_req_waiting...............: avg=5.55ms  min=185µs    med=4.72ms max=146.84ms p(90)=8.71ms p(95)=10.81ms
     http_reqs......................: 1070002 17832.344873/s
     iteration_duration.............: avg=5.6ms   min=222.41µs med=4.77ms max=168.08ms p(90)=8.76ms p(95)=10.87ms
     iterations.....................: 1070002 17832.344873/s
     vus............................: 100     min=100        max=100
     vus_max........................: 100     min=100        max=100


running (1m00.0s), 000/100 VUs, 1070002 complete and 0 interrupted iterations
default ✓ [======================================] 100 VUs  1m0s
```
