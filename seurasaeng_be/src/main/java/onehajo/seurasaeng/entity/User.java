package onehajo.seurasaeng.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.*;
import jakarta.validation.constraints.NotNull;
import org.hibernate.annotations.ColumnDefault;


@Entity
@Getter
@Setter
@Builder
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "users", schema = "seurasaeng_test")
public class User {

    @Id
    // Auto Increment
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "user_id")
    private Long id;

    @NotNull
    @Column(name = "user_name", columnDefinition = "varchar(50)")
    @NotBlank(message = "이름은 필수 입력 값입니다.")
    private String name;

    @Email
    @NotNull
    @Column(name = "user_email", columnDefinition = "varchar(255)")
    @NotBlank(message = "이메일은 필수 입력 값입니다.")
    private String email;

    @NotNull
    @Column(name = "user_password", columnDefinition = "varchar(255)")
    @NotBlank(message = "비밀번호는 필수 입력 값입니다.")
    private String password;

    @Column(name = "user_image", columnDefinition = "TEXT")
    private String image;

    @NotNull
    @Builder.Default
    @Column(name = "user_read_newnoti", columnDefinition = "boolean default false")
    private boolean read_newnoti = false;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "favorites_work_id")
    @ColumnDefault("4")
    private Shuttle favorites_work_id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "favorites_home_id")
    @ColumnDefault("9")
    private Shuttle favorites_home_id;
}
