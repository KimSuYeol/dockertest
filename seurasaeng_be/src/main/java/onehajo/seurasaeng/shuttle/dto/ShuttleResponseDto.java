package onehajo.seurasaeng.shuttle.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ShuttleResponseDto {
    private Long id;
    private String shuttleName;
    private String departureName;
    private String destinationName;
    private Boolean commute;
}
