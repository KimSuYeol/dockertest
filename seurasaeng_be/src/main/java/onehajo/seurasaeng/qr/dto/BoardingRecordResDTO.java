package onehajo.seurasaeng.qr.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
@AllArgsConstructor
public class BoardingRecordResDTO {
    private Long boarding_id;
    private String departure;
    private String destination;
    private LocalDateTime boarding_time;
}
