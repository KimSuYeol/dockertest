package onehajo.seurasaeng.shuttle;

import jakarta.transaction.Transactional;
import onehajo.seurasaeng.entity.Location;
import onehajo.seurasaeng.entity.Shuttle;
import onehajo.seurasaeng.shuttle.repository.LocationRepository;
import onehajo.seurasaeng.shuttle.repository.ShuttleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
@Transactional
public class ShuttleIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ShuttleRepository shuttleRepository;

    @Autowired
    private LocationRepository locationRepository;

    @BeforeEach
    void setup() {
        Location departure = Location.builder()
                .locationId(1L)
                .locationName("아이티센타워")
                .latitude(37.5665)
                .longitude(126.9780)
                .build();

        Location destination = Location.builder()
                .locationId(2L)
                .locationName("양재역")
                .latitude(37.5665)
                .longitude(126.9780)
                .build();

        departure = locationRepository.save(departure);
        destination = locationRepository.save(destination);

        Shuttle shuttle = Shuttle.builder()
                .shuttleName("양재")
                .departure(departure)
                .destination(destination)
                .isCommute(true)
                .build();
        shuttleRepository.save(shuttle);
    }

    @Test
    @DisplayName("노선 목록 조회 API - 통합테스트 | 데이터 존재시 200 OK")
    void testGetShuttles() throws Exception {
        mockMvc.perform(get("/api/shuttles")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].shuttleName").value("양재"))
                .andExpect(jsonPath("$[0].departureName").value("아이티센타워"))
                .andExpect(jsonPath("$[0].destinationName").value("양재역"))
                .andExpect(jsonPath("$[0].commute").value(true));
    }

    @Test
    @DisplayName("노선 목록 조회 API - 통합테스트 | 데이터 없을 시 204 No Content")
    void testGetShuttles_No_Content() throws Exception {
        shuttleRepository.deleteAll();
        locationRepository.deleteAll();

        mockMvc.perform(get("/api/shuttles")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());
    }

    @Test
    @DisplayName("위치 정보 포함 노선 목록 조회 API - 통합테스트 | 데이터 존재시 200 OK")
    void testGetShuttlesWithLocation() throws Exception {
        mockMvc.perform(get("/api/shuttles/locations")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].departureLatitude").value(37.5665))
                .andExpect(jsonPath("$[0].departureLongitude").value(126.9780))
                .andExpect(jsonPath("$[0].destinationLatitude").value(37.5665))
                .andExpect(jsonPath("$[0].destinationLongitude").value(126.9780));
    }

    @Test
    @DisplayName("위치 정보 포함 노선 목록 조회 API - 통합테스트 | 데이터 없을 시 204 No Content")
    void testGetShuttlesWithLocation_No_Content() throws Exception {
        shuttleRepository.deleteAll();
        locationRepository.deleteAll();

        mockMvc.perform(get("/api/shuttles/locations")
                .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isNoContent());
    }
}
