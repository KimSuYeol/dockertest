package onehajo.seurasaeng.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Entity
@Getter
@Builder
@AllArgsConstructor
@Table(name = "answer", schema = "seurasaeng_test")
public class Answer {

    @Id
    // Auto Increment
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "answer_id")
    private Long id;

    // 외래키 inquiry_id
    @NotNull
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inquiry_id")
    private Inquiry inquiry;

    // 외래키 manager_id
    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "manager_id")
    private Manager manager;

    @Column(name = "answer_content", columnDefinition = "TEXT")
    private String answer;

    @NotNull
    @Column(name = "answer_created_at", columnDefinition = "timestamp")
    private LocalDateTime created_at;

    // 생성자
    public Answer() {}
}

