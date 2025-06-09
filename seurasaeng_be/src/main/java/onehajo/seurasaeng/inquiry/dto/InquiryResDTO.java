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
public class InquiryResDTO {
    private Long id;
    private String title;
    private LocalDateTime created_at;
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private boolean answer_status;
}
