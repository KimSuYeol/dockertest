package onehajo.seurasaeng.shuttle.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class ShuttleWithTimetableDto {
    private Long shuttleId;          // 노선 ID
    private String shuttleName;      // 셔틀명
    private String spotName;         // 거점 (출발지 or 도착지)
    private String duration;         // 소요시간 ("15분")
    private String totalSeats;       // 총인원수 ("45명")
    private String boardingPoint;    // 탑승 장소 (출발/도착 장소)
    private List<TimetableDto> timetables; // 시간표 리스트

}
