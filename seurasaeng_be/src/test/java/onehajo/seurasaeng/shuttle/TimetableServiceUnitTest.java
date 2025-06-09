package onehajo.seurasaeng.shuttle;

import onehajo.seurasaeng.entity.Location;
import onehajo.seurasaeng.entity.Shuttle;
import onehajo.seurasaeng.entity.Timetable;
import onehajo.seurasaeng.shuttle.dto.TimetableResponseDto;
import onehajo.seurasaeng.shuttle.dto.UpdateTimetableRequestDto;
import onehajo.seurasaeng.shuttle.repository.ShuttleRepository;
import onehajo.seurasaeng.shuttle.repository.TimetableRepository;
import onehajo.seurasaeng.shuttle.service.TimetableService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TimetableServiceUnitTest {

    @InjectMocks
    private TimetableService timetableService;

    @Mock
    private ShuttleRepository shuttleRepository;

    @Mock
    private TimetableRepository timetableRepository;

    @Test
    @DisplayName("시간표 목록 조회 API - 단위테스트")
    void getCommuteTimetableSuccess() {
        // Given
        Location departure = Location.builder()
                .locationName("정부과천청사역")
                .build();

        Location destination = Location.builder()
                .locationName("아이티센타워")
                .build();

        Shuttle shuttle = Shuttle.builder()
                .id(1L)
                .shuttleName("과천-센타워 셔틀")
                .departure(departure)
                .destination(destination)
                .isCommute(true)
                .build();

        Timetable timetable = Timetable.builder()
                .shuttle(shuttle)
                .departureTime(LocalTime.of(7, 20))
                .boardingLocation("7번출구 앞")
                .dropoffLocation("센타워 정문")
                .arrivalMinutes(15)
                .totalSeats(45)
                .build();


        when(shuttleRepository.findByIsCommute(true)).thenReturn(List.of(shuttle));
        when(timetableRepository.findByShuttleOrderByDepartureTimeAsc(shuttle)).thenReturn(List.of(timetable));


        TimetableResponseDto response = timetableService.getTimetable();

        assertThat(response).isNotNull();
        assertThat(response.getCommute()).hasSize(1);
        assertThat(response.getCommute().getFirst().getShuttleName()).isEqualTo("과천-센타워 셔틀");
        assertThat(response.getCommute().getFirst().getSpotName()).isEqualTo("정부과천청사역");
        assertThat(response.getCommute().getFirst().getBoardingPoint()).isEqualTo("7번출구 앞");
        assertThat(response.getCommute().getFirst().getDuration()).isEqualTo("15분");
        assertThat(response.getCommute().getFirst().getTotalSeats()).isEqualTo("45명");

        verify(shuttleRepository, times(1)).findByIsCommute(true);
    }

    @Test
    @DisplayName("시간표 수정 API - 단위테스트 | 정상 케이스")
    void updateTimetableSuccess() {

        Shuttle shuttle = Shuttle.builder()
                .id(1L)
                .shuttleName("정부과천청사 셔틀")
                .build();

        Timetable timetable1 = Timetable.builder()
                .id(1L)
                .shuttle(shuttle)
                .departureTime(LocalTime.of(7, 20))
                .boardingLocation("7번출구 앞")
                .dropoffLocation("G동 옆")
                .arrivalMinutes(15)
                .totalSeats(45)
                .build();

        Timetable timetable2 = Timetable.builder()
                .id(2L)
                .shuttle(shuttle)
                .departureTime(LocalTime.of(7, 40))
                .boardingLocation("7번출구 앞")
                .dropoffLocation("G동 옆")
                .arrivalMinutes(15)
                .totalSeats(45)
                .build();

        UpdateTimetableRequestDto request = new UpdateTimetableRequestDto(
                shuttle.getId(),
                List.of(
                        new UpdateTimetableRequestDto.TimetableDto("1회", "08:00"),
                        new UpdateTimetableRequestDto.TimetableDto("2회", "08:30")
                )
        );

        when(shuttleRepository.findById(shuttle.getId())).thenReturn(Optional.of(shuttle));
        when(timetableRepository.findByShuttleOrderByDepartureTimeAsc(shuttle)).thenReturn(List.of(timetable1, timetable2));

        // When
        timetableService.updateTimetable(request);

        // Then
        assertThat(timetable1.getDepartureTime()).isEqualTo(LocalTime.of(8, 0));
        assertThat(timetable2.getDepartureTime()).isEqualTo(LocalTime.of(8, 30));

        verify(timetableRepository).saveAll(List.of(timetable1, timetable2));
    }

    @Test
    @DisplayName("시간표 수정 API - 단위테스트 | 시간표 개수 mismatch 예외")
    void updateTimetableSizeMismatch() {

        Shuttle shuttle = Shuttle.builder()
                .id(1L)
                .shuttleName("정부과천청사 셔틀")
                .build();

        Timetable timetable1 = Timetable.builder()
                .id(1L)
                .shuttle(shuttle)
                .departureTime(LocalTime.of(7, 20))
                .build();

        Timetable timetable2 = Timetable.builder()
                .id(2L)
                .shuttle(shuttle)
                .departureTime(LocalTime.of(7, 40))
                .build();

        UpdateTimetableRequestDto request = new UpdateTimetableRequestDto(
                shuttle.getId(),
                List.of(
                        new UpdateTimetableRequestDto.TimetableDto("1회", "08:00")
                )
        );

        when(shuttleRepository.findById(shuttle.getId())).thenReturn(Optional.of(shuttle));
        when(timetableRepository.findByShuttleOrderByDepartureTimeAsc(shuttle)).thenReturn(List.of(timetable1, timetable2));

        assertThrows(IllegalArgumentException.class, () -> timetableService.updateTimetable(request));
    }
}