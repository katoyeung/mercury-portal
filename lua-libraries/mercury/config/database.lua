local _M = {
    redis = {
        host = os.getenv("REDIS_HOST") or "127.0.0.1",
        port = os.getenv("REDIS_PORT") or 6379,
        password = os.getenv("REDIS_PASSWORD"),
        db = os.getenv("REDIS_DB") or 0,
        timeout = os.getenv("REDIS_TIMEOUT") or 1000,
        keepalive_timeout = os.getenv("REDIS_KEEPALIVE_TIMEOUT") or 1000,
        pool_size = os.getenv("REDIS_POOL_SIZE") or 100,
    },
}

return _M
