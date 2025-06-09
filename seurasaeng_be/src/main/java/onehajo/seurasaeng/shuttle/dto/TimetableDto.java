package onehajo.seurasaeng.shuttle.dto;

import lombok.Builder;
import lombok.Getter;


@Getter
@Builder
public class TimetableDto {
    private String turn;          // "1회", "2회"
    private String departureTime; // "07:20"
}
