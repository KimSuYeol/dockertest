package onehajo.seurasaeng.shuttle.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ShuttleWithLocationResponseDto {
    private Long id;
    private String shuttleName;
    private String departureName;
    private Double departureLatitude;
    private Double departureLongitude;
    private String destinationName;
    private Double destinationLatitude;
    private Double destinationLongitude;
    private Boolean commute;
}
