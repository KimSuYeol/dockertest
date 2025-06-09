package onehajo.seurasaeng.inquiry.repository;

import onehajo.seurasaeng.entity.Answer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AnswerRepository extends JpaRepository<Answer, Long> {
    Optional<Answer> findByInquiryId(Long inquiry_id);

    void deleteByInquiryId(Long inquiry_id);
}
