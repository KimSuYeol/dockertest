package onehajo.seurasaeng.shuttle;

import jakarta.servlet.http.HttpServletRequest;
import onehajo.seurasaeng.entity.Shuttle;
import onehajo.seurasaeng.entity.User;
import onehajo.seurasaeng.user.dto.FavoriteShuttleResDto;
import onehajo.seurasaeng.user.repository.UserRepository;
import onehajo.seurasaeng.util.JwtUtil;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;


import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FavoriteShuttleServiceUnitTest {

    @InjectMocks
    private onehajo.seurasaeng.user.service.UserService userService;

    @Mock
    private UserRepository userRepository;

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private HttpServletRequest request;

    @Test
    @DisplayName("즐겨찾기 조회 - 단위테스트")
    void getFavoriteShuttleIdsTest() {

        Shuttle commuteShuttle = Shuttle.builder()
                .id(1L)
                .shuttleName("출근 셔틀")
                .build();

        Shuttle offworkShuttle = Shuttle.builder()
                .id(2L)
                .shuttleName("퇴근 셔틀")
                .build();

        User user = User.builder()
                .id(100L)
                .name("홍길동")
                .email("hong@test.com")
                .password("password")
                .favorites_work_id(commuteShuttle)
                .favorites_home_id(offworkShuttle)
                .build();

        String token = "mockToken";
        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);
        when(jwtUtil.getIdFromToken(token)).thenReturn(100L);
        when(userRepository.findById(100L)).thenReturn(java.util.Optional.of(user));

        FavoriteShuttleResDto response = userService.getFavoriteShuttleIds(request);

        assertThat(response.getFavoritesWorkId()).isEqualTo(1L);
        assertThat(response.getFavoritesHomeId()).isEqualTo(2L);

        verify(jwtUtil, times(1)).getIdFromToken(token);
        verify(userRepository, times(1)).findById(100L);
    }
}