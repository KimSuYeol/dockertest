package onehajo.seurasaeng.redis.controller;

import lombok.RequiredArgsConstructor;
import onehajo.seurasaeng.redis.service.RedisService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/redis")
public class RedisController {

    private final RedisService redisService;

    // 저장: POST /redis/save?key=testKey&value=testValue
    @PostMapping("/save")
    public String save(@RequestParam String key, @RequestParam String value) {
        redisService.save(key, value);
        return "저장 완료: " + key + " = " + value;
    }

    // 조회: GET /redis/get?key=testKey
    @GetMapping("/get")
    public String get(@RequestParam String key) {
        String value = redisService.get(key);
        return value != null ? "조회 결과: " + value : "해당 키가 존재하지 않습니다.";
    }
}