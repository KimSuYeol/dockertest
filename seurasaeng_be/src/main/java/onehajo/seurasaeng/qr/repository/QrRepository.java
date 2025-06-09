package onehajo.seurasaeng.qr.repository;

import onehajo.seurasaeng.entity.Qr;
import onehajo.seurasaeng.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface QrRepository extends JpaRepository<Qr, Long> {
    Optional<Qr> findByUser(User user);
    Optional<Qr> findByUserId(Long userId);
}