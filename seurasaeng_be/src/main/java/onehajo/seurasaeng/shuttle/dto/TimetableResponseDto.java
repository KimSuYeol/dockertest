package onehajo.seurasaeng.shuttle.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class TimetableResponseDto {
    private List<ShuttleWithTimetableDto> commute; // 출근
    private List<ShuttleWithTimetableDto> offwork; // 퇴근
}
