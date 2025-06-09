package onehajo.seurasaeng.shuttle;

import jakarta.transaction.Transactional;
import onehajo.seurasaeng.entity.Location;
import onehajo.seurasaeng.entity.Shuttle;
import onehajo.seurasaeng.entity.User;
import onehajo.seurasaeng.shuttle.repository.LocationRepository;
import onehajo.seurasaeng.shuttle.repository.ShuttleRepository;
import onehajo.seurasaeng.user.repository.UserRepository;
import onehajo.seurasaeng.util.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;


import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
@Transactional
public class FavoriteShuttleIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ShuttleRepository shuttleRepository;

    @Autowired
    private LocationRepository locationRepository;

    @Autowired
    private JwtUtil jwtUtil;

    private String token;

    @BeforeEach
    void setUp() {
        Location departure = locationRepository.save(Location.builder()
                .locationName("정부과천청사역")
                .latitude(37.4254)
                .longitude(126.9892)
                .build());

        Location destination = locationRepository.save(Location.builder()
                .locationName("아이티센타워")
                .latitude(37.5013)
                .longitude(127.0396)
                .build());

        Shuttle commuteShuttle = shuttleRepository.save(Shuttle.builder()
                .shuttleName("출근 셔틀")
                .departure(departure)
                .destination(destination)
                .isCommute(true)
                .build());

        Shuttle offworkShuttle = shuttleRepository.save(Shuttle.builder()
                .shuttleName("퇴근 셔틀")
                .departure(destination)
                .destination(departure)
                .isCommute(false)
                .build());

        User user = User.builder()
                .name("홍길동")
                .email("hong@test.com")
                .password("password")
                .favorites_work_id(commuteShuttle)
                .favorites_home_id(offworkShuttle)
                .build();

        userRepository.save(user);

        token = jwtUtil.generateToken(user.getId(), user.getName(), user.getEmail());
    }

    @Test
    @DisplayName("즐겨찾기 조회 API - 통합테스트 | 정상 200 OK")
    void getFavoriteShuttleSuccess() throws Exception {
        mockMvc.perform(get("/api/users/me/preferences")
                        .header("Authorization", "Bearer " + token)
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.favoritesWorkId").exists())
                .andExpect(jsonPath("$.favoritesHomeId").exists());
    }
}