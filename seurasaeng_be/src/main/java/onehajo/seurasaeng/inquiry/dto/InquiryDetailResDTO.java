package onehajo.seurasaeng.inquiry.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InquiryDetailResDTO {
    private Long inquiry_id;
    private String user_name;
    private String title;
    private String content;
    private LocalDateTime created_at;
    private boolean answer_status;
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private AnswerResDTO answer;
}
