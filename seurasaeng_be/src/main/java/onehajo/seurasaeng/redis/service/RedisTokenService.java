package onehajo.seurasaeng.redis.service;

import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;

@Service
public class RedisTokenService {

    private final String TOKEN_PREFIX = "JWT:";

    private final RedisTemplate<String, String> redisTemplate;

    public RedisTokenService(RedisTemplate<String, String> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    // 토큰 저장
    public void saveToken(long id, String token, long expirationMillis) {
        redisTemplate.opsForValue().set(TOKEN_PREFIX + id, token);
    }

    // 토큰 조회
    public String getToken(long id) {
        return redisTemplate.opsForValue().get(TOKEN_PREFIX + id);
    }

    // 토큰 삭제 (로그아웃 등)
    public void deleteToken(long id) {
        redisTemplate.delete(TOKEN_PREFIX + id);
    }
}

