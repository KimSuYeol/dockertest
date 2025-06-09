package onehajo.seurasaeng.qr.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.qr.dto.ValidUserResDTO;
import onehajo.seurasaeng.qr.service.QRService;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/users/me/qr")
public class QRController {
    private final QRService qrService;

    // QR 생성 test
    @GetMapping("/generate/test")
    public ResponseEntity<?> generateQR() throws Exception {
        log.info("test");

        HttpHeaders headers = new HttpHeaders();
        headers.add("Content-Type", "image/png");

        qrService.generateQRCode(1, "minjin@test.com");

        return new ResponseEntity<>(headers, HttpStatus.OK);
    }

    @GetMapping
    public ResponseEntity<?> getQRByUserId(@RequestParam Long user_id) {
        String base64Image = qrService.getQRCodeByUserId(user_id);

        Map<String, String> response = new HashMap<>();
        response.put("qr_code", base64Image);

        return ResponseEntity.ok(response);
    }

    // 사용자 유효성 확인
    @PostMapping("/valid")
    public ValidUserResDTO validUser(@RequestParam String qrCode, @RequestParam Long shuttle_id) throws Exception {
        return qrService.userValidate(qrCode, shuttle_id);
    }
}
