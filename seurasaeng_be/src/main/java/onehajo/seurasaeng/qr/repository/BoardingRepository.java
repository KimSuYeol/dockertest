package onehajo.seurasaeng.qr.repository;

import onehajo.seurasaeng.entity.Boarding;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface BoardingRepository extends JpaRepository<Boarding, Long> {
    @Query("SELECT b FROM Boarding b WHERE b.user_id = :user_id ORDER BY b.boarding_time DESC")
    List<Boarding> findByUser_idOrderByBoarding_timeDesc(@Param("user_id") Long user_id);

    // 중복 탑승 여부 확인
    @Query("SELECT CASE WHEN COUNT(b) > 0 THEN true ELSE false END FROM Boarding b " +
            "WHERE b.user_id = :userId AND b.shuttle.id = :shuttleId " +
            "AND b.boarding_time BETWEEN :startTime AND :endTime")
    boolean existsByUser_idAndShuttleIdAndBoarding_timeBetween(
            @Param("userId") Long userId,
            @Param("shuttleId") Long shuttleId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);
}
