package onehajo.seurasaeng.user.repository;

import onehajo.seurasaeng.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    // 사용자 이름으로 중복 여부 확인
    boolean existsByName(String name);

    // 사용자 이름으로 조회 (로그인용 등)
    Optional<User> findByName(String name);

    Optional<User> findByEmail(String email);

    Optional<User> findByIdAndEmail(Long id, String email);

}
