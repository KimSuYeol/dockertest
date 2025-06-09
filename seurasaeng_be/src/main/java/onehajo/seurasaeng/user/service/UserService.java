package onehajo.seurasaeng.user.service;

import jakarta.persistence.EntityNotFoundException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.transaction.Transactional;
import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.entity.Shuttle;
import onehajo.seurasaeng.entity.User;
import onehajo.seurasaeng.qr.exception.UserNotFoundException;
import onehajo.seurasaeng.redis.service.RedisTokenService;
import onehajo.seurasaeng.shuttle.repository.ShuttleRepository;
import onehajo.seurasaeng.user.exception.*;
import onehajo.seurasaeng.user.repository.UserRepository;
import onehajo.seurasaeng.util.JwtUtil;
import onehajo.seurasaeng.user.dto.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Slf4j
@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final RedisTokenService redisTokenService;
    private final ShuttleRepository shuttleRepository;


    public UserService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil,
                       RedisTokenService redisTokenService, ShuttleRepository shuttleRepository) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.redisTokenService = redisTokenService;
        this.shuttleRepository = shuttleRepository;
    }

    @Transactional
    public String registerUser(SignUpReqDTO request) {
        // 이메일 도메인 검사
        String email = request.getEmail();
        if (!email.endsWith("@gmail.com")) {
            throw new UnAuthenticatedEmailException("gmail.com 이메일만 가입할 수 있습니다.");
        }

        if (userRepository.existsByName(request.getName())) {
            throw new RuntimeException("이미 존재하는 사용자입니다.");
        }

        Shuttle defaultWork = shuttleRepository.getReferenceById(4L);
        Shuttle defaultHome = shuttleRepository.getReferenceById(9L);

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .favorites_work_id(defaultWork)
                .favorites_home_id(defaultHome)
                .build();

        userRepository.save(user);
        userRepository.flush();

        String token = jwtUtil.generateToken(user.getId(), user.getName(), user.getEmail(), request.getRole());
        redisTokenService.saveToken(user.getId(), token, jwtUtil.getExpiration());

        return token;
    }

    @Transactional
    public String[] loginUser(LoginReqDTO request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("비밀번호가 일치하지 않습니다.");
        }

        String[] result = new String[2];
        String token = redisTokenService.getToken(user.getId());
        result[0] = token;
        result[1] = jwtUtil.getRoleFromToken(token);

        log.info(result[0]);
        log.info(result[1]);

        return result; // ✅ 컨트롤러에서 Authorization 헤더로 설정
    }

    public String validateDuplicateUserEmail(String email) {
        Optional<User> findUser = userRepository.findByEmail(email);
        if (findUser.isPresent()) {
            throw new DuplicateUserException("이미 존재하는 회원입니다.");
        }
        return email;
    }

    @Transactional
    public String remakeToken(AutoLoginReqDTO request) {
        redisTokenService.deleteToken(request.getId());

        String token = jwtUtil.generateToken(request.getId(), request.getName(), request.getPassword(), request.getRole());
        redisTokenService.saveToken(request.getId(), token, jwtUtil.getExpiration());

        return token;
    }

    public void updatePasswordByEmail(String password, String email) {
        Optional<User> findUsers = userRepository.findByEmail(email);
        if (findUsers.isEmpty()) {
            throw new EntityNotFoundException("email에 정보가 맞지않습니다.");
        }

        User user = findUsers.get();
        user.setPassword(password); // 비밀번호 설정
        userRepository.save(user);
    }

    public MyPageResDTO getMyUsers(HttpServletRequest request) {
        String token = request.getHeader("Authorization").replace("Bearer ", "");
        Long id = jwtUtil.getIdFromToken(token);
        String name = jwtUtil.getNameFromToken(token);
        String email = jwtUtil.getEmailFromToken(token);

        return MyPageResDTO.builder()
                .id(id)
                .name(name)
                .email(email)
                .build();
    }

    @Transactional
    public MyInfoResDTO getMyInfo(HttpServletRequest request, MyInfoReqDTO info) {
        String token = request.getHeader("Authorization").replace("Bearer ", "");
        Long id = jwtUtil.getIdFromToken(token);

        User user = userRepository.findById(id).orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));
        // 사용자 정보 수정
        user.setPassword(info.getPassword());
        //user.setImage(info.getImage());
        //userRepository.save(user);
        userRepository.flush();

        return MyInfoResDTO.builder()
                .name(user.getName())
                //.image(user.getImage())
                .build();
    }

    public FavoriteShuttleResDto getFavoriteShuttleIds(HttpServletRequest request) {
        String token = request.getHeader("Authorization").replace("Bearer ", "");
        Long id = jwtUtil.getIdFromToken(token);

        User user = userRepository.findById(id).orElseThrow(() -> new UserNotFoundException("사용자를 찾을 수 없습니다."));

        return FavoriteShuttleResDto.builder()
                .favoritesWorkId(user.getFavorites_work_id().getId())
                .favoritesHomeId(user.getFavorites_home_id().getId())
                .build();
    }
}
