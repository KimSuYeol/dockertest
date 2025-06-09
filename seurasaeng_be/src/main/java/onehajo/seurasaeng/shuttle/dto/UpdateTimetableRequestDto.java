package onehajo.seurasaeng.shuttle.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
@AllArgsConstructor
public class UpdateTimetableRequestDto {

    @NotNull
    private Long shuttleId;

    @NotEmpty
    private List<TimetableDto> timetables;

    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TimetableDto {
        @NotBlank
        private String turn;

        @NotBlank
        private String departureTime; // (HH:mm)
    }
}
