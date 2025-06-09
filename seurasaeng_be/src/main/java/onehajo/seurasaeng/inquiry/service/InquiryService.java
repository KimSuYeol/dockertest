package onehajo.seurasaeng.inquiry.service;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.entity.Answer;
import onehajo.seurasaeng.entity.Inquiry;
import onehajo.seurasaeng.entity.Manager;
import onehajo.seurasaeng.entity.User;
import onehajo.seurasaeng.inquiry.dto.*;
import onehajo.seurasaeng.inquiry.exception.InquiryException;
import onehajo.seurasaeng.inquiry.exception.UserException;
import onehajo.seurasaeng.inquiry.repository.AnswerRepository;
import onehajo.seurasaeng.inquiry.repository.InquiryRepository;
import onehajo.seurasaeng.inquiry.repository.ManagerRepository;
import onehajo.seurasaeng.qr.exception.UserNotFoundException;
import onehajo.seurasaeng.user.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class InquiryService {
    private final InquiryRepository inquiryRepository;
    private final UserRepository userRepository;
    private final AnswerRepository answerRepository;
    private final ManagerRepository managerRepository;

    // 문의 작성
    public InquiryDetailResDTO createInquiry(Long user_id, InquiryReqDTO inquiryReqDTO) {
        User user = validateUserExists(user_id);

        Inquiry inquiry = buildInquiry(user, inquiryReqDTO);

        Inquiry savedInquiry = inquiryRepository.save(inquiry);

        return buildInquiryDetailResponse(savedInquiry, user_id, null);
    }

    // 사용자별 문의 목록 조회
    public List<InquiryResDTO> getInquiriesByUserId(Long user_id) {
        User user = validateUserExists(user_id);

        List<Inquiry> inquiryList = inquiryRepository.findByUserOrderByCreatedAtDesc(user);

        return inquiryList.stream()
                .map(this::buildInquiryResponseWithStatus)
                .collect(Collectors.toList());
    }

    // 관리자 - 문의 목록 전제 조회
    public List<InquiryResDTO> getInquiriesByManagerId(Long manager_id) {
        validateManagerExists(manager_id);

        List<Inquiry> inquiryList = inquiryRepository.findAll();

        return inquiryList.stream()
                .map(this::buildInquiryResponseWithStatus)
                .collect(Collectors.toList());
    }

    // 문의 상세 조회
    public InquiryDetailResDTO getInquiryDetail(Long id, Long user_id) {
        Inquiry inquiry = validateInquiryExists(id);

        validateInquiryOwner(inquiry, user_id);

        // answer_status가 true일 때 -> Answer 조회, false -> null
        AnswerResDTO answerDTO = findAnswerByInquiry(inquiry);

        return buildInquiryDetailResponse(inquiry, user_id, answerDTO);
    }

    // 문의 삭제
    @Transactional
    public void deleteInquiryById(Long id, Long user_id) {
        try {
            Inquiry inquiry = validateInquiryExists(id);

            validateDeleteInquiryOwner(inquiry, user_id);

            // 답변 내용이 있다면 답변 삭제
            deleteAnswerIfExist(inquiry);

            inquiryRepository.deleteById(id);
        } catch (InquiryException | UserException | UserNotFoundException e) {
            throw e;
        } catch (Exception e) {
            log.error("문의 삭제 실패 - inquiry_id : {}", id);
            throw new RuntimeException("문의 삭제 실패", e);
        }
    }

    // 답변 생성
    @Transactional
    public InquiryDetailResDTO saveAnswer(Long inquiry_id, Long manager_id, AnswerReqDTO request) {
        Inquiry inquiry = validateInquiryExists(inquiry_id);
        Manager manager = validateManagerExists(manager_id);

        Answer answer = buildAnswer(inquiry, manager, request);
        Answer savedAnswer = answerRepository.save(answer);
        log.info("Answer 저장 완료 - answerId: {}", savedAnswer.getId());

        inquiryRepository.updateAnswerStatus(inquiry_id, true);

        Inquiry updatedInquiry = validateInquiryExists(inquiry_id);

        AnswerResDTO answerDTO = buildAnswerResponse(savedAnswer);

        return buildInquiryDetailResponse(updatedInquiry, updatedInquiry.getUser().getId(), answerDTO);
    }

    /** 유효성 검증
     */
    private User validateUserExists(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("사용자를 찾을 수 없습니다."));
    }

    private Inquiry validateInquiryExists(Long inquiry_id) {
        return inquiryRepository.findById(inquiry_id)
                .orElseThrow(() -> new InquiryException("문의를 찾을 수 없습니다."));
    }

    private Manager validateManagerExists(Long manager_id) {
        return managerRepository.findById(manager_id)
                .orElseThrow(() -> new IllegalArgumentException("관리자를 찾을 수 없습니다."));
    }

    private void validateInquiryOwner(Inquiry inquiry, Long user_id) {
        if (!inquiry.getUser().getId().equals(user_id)) {
            throw new UserException("본인의 문의만 접근할 수 있습니다.");
        }
    }

    private void validateDeleteInquiryOwner(Inquiry inquiry, Long user_id) {
        if (!inquiry.getUser().getId().equals(user_id)) {
            throw new RuntimeException("본인의 문의만 삭제할 수 있습니다.");
        }
    }

    /**
     * 사용자 이름 가져오기
     */
    private String getUserName(Long user_id) {
        return userRepository.findById(user_id).map(User::getName).orElse("알 수 없는 사용자입니다.");
    }

    /**
     * builder 생성
     */
    private Inquiry buildInquiry(User user, InquiryReqDTO request) {
        return Inquiry.builder()
                .user(user)
                .title(request.getTitle())
                .content(request.getContent())
                .created_at(LocalDateTime.now())
                .answer_status(false)
                .build();
    }

    private InquiryDetailResDTO buildInquiryDetailResponse(Inquiry inquiry, Long user_id, AnswerResDTO answerDto) {
        return InquiryDetailResDTO.builder()
                .inquiry_id(inquiry.getId())
                .user_name(getUserName(user_id))
                .title(inquiry.getTitle())
                .content(inquiry.getContent())
                .created_at(inquiry.getCreated_at())
                .answer_status(inquiry.isAnswer_status())
                .answer(answerDto)
                .build();
    }

    private InquiryResDTO buildInquiryResponse(Inquiry inquiry) {
        return InquiryResDTO.builder()
                .id(inquiry.getId())
                .title(inquiry.getTitle())
                .created_at(inquiry.getCreated_at())
                .build();
    }

    private InquiryResDTO buildInquiryResponseWithStatus(Inquiry inquiry) {
        return InquiryResDTO.builder()
                .id(inquiry.getId())
                .title(inquiry.getTitle())
                .created_at(inquiry.getCreated_at())
                .answer_status(inquiry.isAnswer_status())
                .build();
    }

    private Answer buildAnswer(Inquiry inquiry, Manager manager, AnswerReqDTO request) {
        return Answer.builder()
                .inquiry(inquiry)
                .manager(manager)
                .answer(request.getContent())
                .created_at(LocalDateTime.now())
                .build();
    }

    private AnswerResDTO buildAnswerResponse(Answer answer) {
        return AnswerResDTO.builder()
                .answer_id(answer.getId())
                .answer_content(answer.getAnswer())
                .created_at(answer.getCreated_at())
                .build();
    }

    private AnswerResDTO findAnswerByInquiry(Inquiry inquiry) {
        if(!inquiry.isAnswer_status()) {
            return null;
        }

        return answerRepository.findByInquiryId(inquiry.getId())
                .map(this::buildAnswerResponse)
                .orElse(null);
    }

    private void deleteAnswerIfExist(Inquiry inquiry) {
        if (inquiry.isAnswer_status()) {
            answerRepository.deleteByInquiryId(inquiry.getId());
        }
    }
}
