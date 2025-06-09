package onehajo.seurasaeng.user.dto;

import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class SignUpReqDTO {

    private String name;
    private String email;
    private String password;

    // 기본 생성자 (필수)
    public SignUpReqDTO() {}
}

