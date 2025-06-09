package onehajo.seurasaeng.inquiry.repository;

import onehajo.seurasaeng.entity.Inquiry;
import onehajo.seurasaeng.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface InquiryRepository extends JpaRepository<Inquiry, Long> {
    @Query("SELECT i FROM Inquiry i WHERE i.user = :user ORDER BY i.created_at DESC")
    List<Inquiry> findByUserOrderByCreatedAtDesc(@Param("user") User user);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Inquiry i SET i.answer_status = :status WHERE i.id = :inquiry_id")
    void updateAnswerStatus(@Param("inquiry_id") Long inquiry_id, @Param("status") boolean status);
}
