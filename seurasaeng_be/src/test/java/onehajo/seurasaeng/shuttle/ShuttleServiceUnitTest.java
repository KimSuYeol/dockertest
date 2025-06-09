package onehajo.seurasaeng.shuttle;

import onehajo.seurasaeng.entity.Location;
import onehajo.seurasaeng.entity.Shuttle;
import onehajo.seurasaeng.shuttle.dto.ShuttleResponseDto;
import onehajo.seurasaeng.shuttle.dto.ShuttleWithLocationResponseDto;
import onehajo.seurasaeng.shuttle.repository.ShuttleRepository;
import onehajo.seurasaeng.shuttle.service.ShuttleService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ShuttleServiceUnitTest {

    @InjectMocks
    private ShuttleService shuttleService;

    @Mock
    private ShuttleRepository shuttleRepository;

    private Shuttle shuttle;

    @BeforeEach
    void setup() {
        Location departure = Location.builder()
                .locationName("아이티센터")
                .latitude(37.5665)
                .longitude(126.9780)
                .build();

        Location destination = Location.builder()
                .locationName("양재역")
                .latitude(37.4837)
                .longitude(127.0354)
                .build();

        shuttle = Shuttle.builder()
                .shuttleName("양재 셔틀")
                .departure(departure)
                .destination(destination)
                .isCommute(true)
                .build();
    }

    @Test
    @DisplayName("노선 목록 조회 단위 테스트")
    void testGetShuttleList() {

        when(shuttleRepository.findAll()).thenReturn(List.of(shuttle));

        List<ShuttleResponseDto> result = shuttleService.getShuttleList();

        assertThat(result).hasSize(1);
        ShuttleResponseDto dto = result.getFirst();
        assertThat(dto.getShuttleName()).isEqualTo("양재 셔틀");
        assertThat(dto.getDepartureName()).isEqualTo("아이티센터");
        assertThat(dto.getDestinationName()).isEqualTo("양재역");
        assertThat(dto.getCommute()).isTrue();
    }

    @Test
    @DisplayName("노선 위치 정보 포함 목록 조회 단위 테스트")
    void testGetShuttleWithLocation() {

        when(shuttleRepository.findAll()).thenReturn(List.of(shuttle));

        List<ShuttleWithLocationResponseDto> result = shuttleService.getShuttleWithLocation();

        assertThat(result).hasSize(1);
        ShuttleWithLocationResponseDto dto = result.getFirst();
        assertThat(dto.getDepartureName()).isEqualTo("아이티센터");
        assertThat(dto.getDepartureLatitude()).isEqualTo(37.5665);
        assertThat(dto.getDepartureLongitude()).isEqualTo(126.9780);
        assertThat(dto.getDestinationName()).isEqualTo("양재역");
        assertThat(dto.getDestinationLatitude()).isEqualTo(37.4837);
        assertThat(dto.getDestinationLongitude()).isEqualTo(127.0354);
        assertThat(dto.getCommute()).isTrue();
    }
}