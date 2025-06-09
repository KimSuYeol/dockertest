package onehajo.seurasaeng.user.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MyInfoReqDTO {
    private String password;
    private String image;
    //long favorites_work_id;
    //long favorites_home_id;
}
