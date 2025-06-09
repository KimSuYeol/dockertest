package onehajo.seurasaeng.user.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class FavoriteShuttleResDto {
    private Long favoritesWorkId;  // 출근 즐겨찾기 노선 ID
    private Long favoritesHomeId;  // 퇴근 즐겨찾기 노선 ID
}
