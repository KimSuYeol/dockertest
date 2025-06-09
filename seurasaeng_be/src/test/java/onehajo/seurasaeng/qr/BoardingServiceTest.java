package onehajo.seurasaeng.qr;

import onehajo.seurasaeng.entity.Location;
import onehajo.seurasaeng.qr.dto.BoardingRecordResDTO;
import onehajo.seurasaeng.qr.repository.BoardingRepository;
import onehajo.seurasaeng.shuttle.repository.ShuttleRepository;
import onehajo.seurasaeng.qr.service.BoardingService;
import onehajo.seurasaeng.entity.Boarding;
import onehajo.seurasaeng.entity.Shuttle;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;


//@ExtendWith(MockitoExtension.class)
@SpringBootTest
public class BoardingServiceTest {

//    @Mock
    @MockBean
    private BoardingRepository boardingRepository;

//    @Mock
    @MockBean
    private ShuttleRepository shuttleRepository;

//    @InjectMocks
    @Autowired
    private BoardingService boardingService;

    private Shuttle shuttle;
    private Boarding boarding;

    @BeforeEach
    void setUp() { // 테스트 데이터
        shuttle = Shuttle.builder()
                .id(1L)
                .shuttleName("청사출근")
                .departure(Location.builder().locationName("청사").build())
                .destination(Location.builder().locationName("아이티센").build())
                .build();

        boarding = Boarding.builder()
                .id(1L)
                .user_id(1L)
                .shuttle(shuttle)
                .boarding_time(LocalDateTime.now())
                .build();
    }

    @Test
    @DisplayName("탑승 기록 저장")
    void saveBoardingRecord() {
        // Given(테스트에 필요한 데이터 준비)
        Long user_id = 1L;
        Long shuttle_id = 1L;

        // shuttleRepository.findById(1L)가 호출 시 -> shuttle 객체를 반환
        given(shuttleRepository.findById(shuttle_id)).willReturn(Optional.of(shuttle));
        // boardingRepository.save(아무 Boarding 객체)가 호출 시 -> boarding 객체
        given(boardingRepository.save(any(Boarding.class))).willReturn(boarding);

        // When (실제로 테스트하고 싶은 메서드 호출)
        Boarding result = boardingService.saveBoardingRecord(user_id, shuttle_id);

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getUser_id()).isEqualTo(user_id);
        assertThat(result.getShuttle().getId()).isEqualTo(shuttle_id);

        // 해당 메서드가 호출됐는지 확인
        verify(shuttleRepository).findById(shuttle_id);
        verify(boardingRepository).save(any(Boarding.class));
    }

    @Test
    @DisplayName("사용자 탑승 기록 조회")
    void getUserBoardingRecord() {
        //Given
        Long user_id = 1L;
        List<Boarding> boardingList = Arrays.asList(boarding);

        // 탑승 기록 목록 조회
        given(boardingRepository.findByUser_idOrderByBoarding_timeDesc(user_id))
                .willReturn(boardingList);
        // 각 탑승 기록의 셔틀 정보 조회
        given(shuttleRepository.findById(shuttle.getId())).willReturn(Optional.of(shuttle));

        //When
        List<BoardingRecordResDTO> result = boardingService.getUserBoardingRecord(user_id);

        //Then
        assertThat(result).hasSize(1);

        BoardingRecordResDTO dto = result.get(0);
        assertThat(dto.getBoarding_id()).isEqualTo(boarding.getId());
        assertThat(dto.getDeparture()).isEqualTo(shuttle.getDeparture().getLocationName());
        assertThat(dto.getDestination()).isEqualTo(shuttle.getDestination().getLocationName());

        verify(boardingRepository).findByUser_idOrderByBoarding_timeDesc(user_id);
        verify(shuttleRepository).findById(shuttle.getId());
    }
}
