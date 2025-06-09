package onehajo.seurasaeng.user.controller;

import jakarta.mail.MessagingException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.transaction.Transactional;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.mail.service.MailService;
import onehajo.seurasaeng.user.service.UserService;
import onehajo.seurasaeng.util.JwtUtil;
import onehajo.seurasaeng.user.dto.*;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;
    @Getter
    private final JwtUtil jwtUtil;
    private final MailService mailService;

    public UserController(UserService userService, JwtUtil jwtUtil, MailService mailService) {
        this.userService = userService;
        this.jwtUtil = jwtUtil;
        this.mailService = mailService;
    }

    @Transactional
    @PostMapping("/signup")
    public ResponseEntity<String> register(@RequestBody SignUpReqDTO request) {
        String token = userService.registerUser(request);
        log.info("회원가입 시도");
        return ResponseEntity.ok(token);
    }

    @PostMapping("/verify-email")
    public ResponseEntity<String> verifyEmail(@RequestParam("email") String email) throws MessagingException {
        String token = userService.validateDuplicateUserEmail(email);
        mailService.joinEmail(email);
        log.info("이메일 중복 확인");
        return ResponseEntity.ok(token);
    }

    @PostMapping("/email")
    public ResponseEntity<String> sendEmailCode(@RequestParam("email") String email) throws MessagingException {
        String code = mailService.joinEmail(email);
        log.info("이메일 인증 코드 전송");

        return new ResponseEntity<String>(code, HttpStatus.OK);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginReqDTO request) {
        String token = userService.loginUser(request);

        return ResponseEntity.ok()
                .header("Authorization", "Bearer " + token) // ✅ JWT를 헤더에 포함
                .body("로그인 성공"); // 혹은 사용자 정보 등 추가 가능
    }

    @GetMapping("/auto-login")
    public ResponseEntity<?> autoLogin(@RequestBody AutoLoginReqDTO request) {
        String token = userService.remakeToken(request);

        return ResponseEntity.ok()
                .header("Authorization", "Bearer " + token) // ✅ JWT를 헤더에 포함
                .body("재로그인 성공"); // 혹은 사용자 정보 등 추가 가능
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<?> lostPassword(@RequestParam("email") String email) throws MessagingException {
        // mailService에서 임시 비밀번호 생성
        // 메일 전송
        // 해당 string으로 update
        String newPassword = mailService.tempPassword(email);
        userService.updatePasswordByEmail(newPassword, email);
        return new ResponseEntity<>(HttpStatus.OK);
    }

    @GetMapping("/me")
    public ResponseEntity<?> myPage(HttpServletRequest request) {
        MyPageResDTO myPageResDTO = userService.getMyUsers(request);

        return new ResponseEntity<MyPageResDTO>(myPageResDTO, HttpStatus.OK);
    }

    @PatchMapping("/me")
    public ResponseEntity<?> updateUser(HttpServletRequest request, @RequestBody MyInfoReqDTO myInfoReqDTO) {
        //MyPageResDTO myPageResDTO = userService.getMyUsers(request);
        MyInfoResDTO myInfoResDTO = userService.getMyInfo(request, myInfoReqDTO);

        return new ResponseEntity<MyInfoResDTO>(myInfoResDTO, HttpStatus.OK);
    }

    @GetMapping("/me/preferences")
    public ResponseEntity<FavoriteShuttleResDto> getFavorites(HttpServletRequest request) {
        FavoriteShuttleResDto response = userService.getFavoriteShuttleIds(request);
        return ResponseEntity.ok(response);
    }
}