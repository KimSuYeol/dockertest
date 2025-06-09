package onehajo.seurasaeng.inquiry.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AnswerResDTO {
    private Long answer_id;
    private String answer_content;
    private LocalDateTime created_at;
}