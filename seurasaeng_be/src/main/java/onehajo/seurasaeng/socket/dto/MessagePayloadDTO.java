package onehajo.seurasaeng.socket.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

/**
 * 소켓 통신 시 클라이언트와 서버 간 송수신하는 공통 메시지 포맷
 */
@Data
public class MessagePayloadDTO {
    private MessageType type;

    @NotNull(message = "노선 ID(routeId)는 필수입니다.")
    private Long routeId;

    @NotNull(message = "위도(latitude)는 필수입니다.")
    private Double latitude;

    @NotNull(message = "경도(longitude)는 필수입니다.")
    private Double longitude;

    private String timestamp;
}
