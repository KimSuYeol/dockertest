package onehajo.seurasaeng.mail.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import jakarta.persistence.EntityNotFoundException;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import onehajo.seurasaeng.entity.User;
import onehajo.seurasaeng.mail.dto.MailResDTO;
import onehajo.seurasaeng.user.repository.UserRepository;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.thymeleaf.context.Context;
import org.thymeleaf.spring6.SpringTemplateEngine;

import java.util.Optional;
import java.util.Random;

@Service
@Transactional
@RequiredArgsConstructor
public class MailService {
    private final JavaMailSender javaMailSender;
    private final SpringTemplateEngine templateEngine;
    private final UserRepository userRepository;

    public void sendEmail(MailResDTO mailResDTO) throws MessagingException {
        MimeMessage mimeMessage = javaMailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "utf-8");

        helper.setFrom(mailResDTO.getMailFrom());
        helper.setTo(mailResDTO.getMailTo());
        helper.setSubject(mailResDTO.getMailSubject());
        helper.setText(mailResDTO.getMailContent(), true);

        javaMailSender.send(mimeMessage);
    }

    public int makeRandomNum() {
        Random random = new Random();
        return random.nextInt(888888) + 111111;
    }

    public String joinEmail(String email) throws MessagingException {
        int checkNum = makeRandomNum();
        String setFrom = "youjiyeon4@gmail.com";
        String subject = "[슬기로운 아이티센 생활] 회원 가입 인증 이메일 입니다.";

        // Thymeleaf context 설정
        Context context = new Context();
        context.setVariable("checkNum", checkNum);

        // HTML 템플릿 처리
        String content = templateEngine.process("welcome", context); // templates/welcome.html

        // 메일 전송
        MimeMessage message = javaMailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

        helper.setFrom(setFrom);
        helper.setTo(email);
        helper.setSubject(subject);
        helper.setText(content, true); // 두 번째 파라미터 true: HTML로 보냄

        javaMailSender.send(message);

        return Integer.toString(checkNum);
    }

    public String tempPassword(String email) throws MessagingException {
        // 존재하는 메일인지 확인
        Optional<User> findUsers = userRepository.findByEmail(email);
        if (!findUsers.isPresent()) {
            throw new EntityNotFoundException("가입된 이메일이 아닙니다.");
        }

        String newPassword = makeRandomPassword();
        String setFrom = "youjiyeon4@gmail.com";
        String subject = "[슬기로운 아이티센 생활] 회원 가입 인증 이메일 입니다.";

        // Thymeleaf context 설정
        Context context = new Context();
        context.setVariable("newPassword", newPassword);

        // HTML 템플릿 처리
        String content = templateEngine.process("remake", context); // templates/remake.html

        // 메일 전송
        MimeMessage message = javaMailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

        helper.setFrom(setFrom);
        helper.setTo(email);
        helper.setSubject(subject);
        helper.setText(content, true); // 두 번째 파라미터 true: HTML로 보냄

        javaMailSender.send(message);

        return newPassword;
    }

    public String makeRandomPassword() {
        StringBuffer temp = new StringBuffer();
        Random rnd = new Random();
        //특수문자 아스키 코드
        int arr[] = {33, 34, 35, 36, 37, 38, 39, 40, 41, 42,
                43, 44, 45, 46, 47, 58, 59, 60, 61, 62,
                63, 64, 91, 92, 93, 94, 95, 96, 123, 124,
                125, 126};
        int n = 0;

        for (int i = 0; i < 10; i++) {
            int rIndex = rnd.nextInt(4);
            switch (rIndex) {
                case 0:
                    // a-z 영어소문자 아스키코드
                    temp.append((char)((int)(rnd.nextInt(26)) + 97));
                    break;
                case 1: // A-Z 영어대문자 아스키코드
                    temp.append((char)((int)(rnd.nextInt(26)) + 65));
                    break;
                case 2:
                    // 0-9 숫자 아스키코드
                    temp.append((rnd.nextInt(10)));
                    break;
                case 3:
                    // arr배열에 담긴 특수문자
                    n = rnd.nextInt(32);
                    temp.append((char)arr[n]);
                    break;
            }
        }
        return (temp.toString());
    }
}
