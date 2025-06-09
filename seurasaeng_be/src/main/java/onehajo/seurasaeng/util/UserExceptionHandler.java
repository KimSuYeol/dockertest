package onehajo.seurasaeng.util;

import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.user.exception.DuplicateUserException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice
@Slf4j
public class UserExceptionHandler {
    /**
     * 이메일 중복 처리 - 404
     */
    @ExceptionHandler(DuplicateUserException.class)
    public ResponseEntity<Map<String, String>> handleUserNotFoundException(DuplicateUserException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", "이메일이 중복되었습니다."));
    }

    /**
     * 일반적인 IllegalArgumentException - 400
     */
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleIllegalArgumentException(IllegalArgumentException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", e.getMessage()));
    }

    /**
     * 기타 예외 - 500
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneralException(Exception e) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "예상치 못한 오류입니다."));
    }
}
