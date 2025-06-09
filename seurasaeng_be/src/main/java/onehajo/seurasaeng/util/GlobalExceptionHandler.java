package onehajo.seurasaeng.util;

import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.qr.exception.InvalidQRCodeException;
import onehajo.seurasaeng.qr.exception.UserNotFoundException;
import onehajo.seurasaeng.shuttle.exception.InvalidTimetableSizeException;
import onehajo.seurasaeng.shuttle.exception.ShuttleNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {
    /**
     * 사용자 없음 예외 처리 - 404
     */
    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleUserNotFoundException(UserNotFoundException e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", "사용자 정보가 없습니다."));
    }

    /**
     * 유효하지 않은 QR 예외 처리 - 400
     */
    @ExceptionHandler(InvalidQRCodeException.class)
    public ResponseEntity<Map<String, String>> handleInvalidQRCodeException(InvalidQRCodeException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", "유효하지 않은 QR 입니다."));
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


    @ExceptionHandler(ShuttleNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleShuttleNotFound(Exception e) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error",  e.getMessage()));
    }

    @ExceptionHandler(InvalidTimetableSizeException.class)
    public ResponseEntity<Map<String, String>> handleInvalidTimetableSize(Exception e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", e.getMessage()));
    }


}
