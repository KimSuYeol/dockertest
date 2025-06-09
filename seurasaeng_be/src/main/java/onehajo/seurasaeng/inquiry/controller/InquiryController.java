package onehajo.seurasaeng.inquiry.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.entity.Inquiry;
import onehajo.seurasaeng.inquiry.dto.AnswerReqDTO;
import onehajo.seurasaeng.inquiry.dto.InquiryDetailResDTO;
import onehajo.seurasaeng.inquiry.dto.InquiryReqDTO;
import onehajo.seurasaeng.inquiry.dto.InquiryResDTO;
import onehajo.seurasaeng.inquiry.service.InquiryService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/inquiries")
public class InquiryController {
    private final InquiryService inquiryService;

    // 문의 생성
    @PostMapping
    public ResponseEntity<?> createInquiry(@RequestParam Long user_id, @RequestBody InquiryReqDTO inquiryReqDTO) {
        InquiryDetailResDTO response = inquiryService.createInquiry(user_id, inquiryReqDTO);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(response);
    }

    // 사용자 별 문의 목록 조회
    @GetMapping
    public ResponseEntity<?> getInquiriesByUserId(@RequestParam Long user_id) {
        List<InquiryResDTO> inquiryList = inquiryService.getInquiriesByUserId(user_id);

        return ResponseEntity.ok(inquiryList);
    }

    @GetMapping("/admin")
    public ResponseEntity<?> getInquiriesByManagerId(@RequestParam Long manager_id) {
        List<InquiryResDTO> inquiryList = inquiryService.getInquiriesByManagerId(manager_id);

        return ResponseEntity.ok(inquiryList);
    }

    // 문의 상세 조회
    @GetMapping("/{id}")
    public ResponseEntity<?> getInquiryDetail(@PathVariable Long id, @RequestParam Long user_id) {
        InquiryDetailResDTO inquiry = inquiryService.getInquiryDetail(id, user_id);

        return ResponseEntity.ok(inquiry);
    }
    
    // 문의 삭제
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteInquiryById(@PathVariable Long id, @RequestParam Long user_id) {
        inquiryService.deleteInquiryById(id, user_id);

        Map<String, String> response = Map.of(
                "message", "문의를 삭제했습니다."
        );

        return ResponseEntity.ok(response);
    }

    // 답변 작성
    @PostMapping("/{id}/answer")
    public ResponseEntity<?> createAnswer(@PathVariable("id") Long id, @RequestParam Long manager_id, @RequestBody AnswerReqDTO request) {
        InquiryDetailResDTO response = inquiryService.saveAnswer(id, manager_id, request);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(response);
    }
}
