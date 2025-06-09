package onehajo.seurasaeng.socket.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;


/**
 * 운행 종료 시 클라이언트로 전송할 메시지 DTO
 */
@Getter
@Builder
public class EndMessagePayloadDTO {
    private final MessageType type;
    private final String timestamp;

    private static final ZoneId KST_ZONE = ZoneId.of("Asia/Seoul");
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * EndMessagePayload 생성 메서드
     * type은 항상 'END'
     * timestamp는 객체 생성 시점의 현재 시간 (KST 기준)
     *
     */
    public static EndMessagePayloadDTO create() {
        return EndMessagePayloadDTO.builder()
                .type(MessageType.END)
                .timestamp(LocalDateTime.now(KST_ZONE).format(FORMATTER))
                .build();
    }
}
