package onehajo.seurasaeng.qr.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.qr.dto.BoardingRecordResDTO;
import onehajo.seurasaeng.qr.service.BoardingService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/shuttle")
public class BoardingController {
    private final BoardingService boardingService;

    @GetMapping("/rides")
    public ResponseEntity<?> getBoardingRecords(@RequestParam Long user_id) {
        List<BoardingRecordResDTO> boardingRecords = boardingService.getUserBoardingRecord(user_id);

        return ResponseEntity.ok(boardingRecords);
    }

    @GetMapping("/count/{shuttleId}")
    public ResponseEntity<Map<String, Long>> getBoardingCount(@PathVariable Long shuttleId) {
        Long count = boardingService.getCurrentBoardingCount(shuttleId);

        Map<String, Long> response = new HashMap<>();
        response.put("count", count);

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/count/{shuttleId}")
    public ResponseEntity<Map<String, String>> resetBoardingCount(@PathVariable Long shuttleId) {
        boardingService.resetBoardingCount(shuttleId);

        Map<String, String> response = Map.of(
                "message", "탑승인원이 삭제되었습니다."
        );

        return ResponseEntity.ok(response);
    }
}
