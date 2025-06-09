package onehajo.seurasaeng.qr.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
@AllArgsConstructor
public class ValidUserResDTO {
    private LocalDateTime boarding_time;
    private String user_name;
    private String departure;
    private String destination;
}
