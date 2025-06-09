package onehajo.seurasaeng.qr.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.zxing.*;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.qr.dto.QrReqDTO;
import onehajo.seurasaeng.qr.dto.ValidUserResDTO;
import onehajo.seurasaeng.qr.exception.InvalidQRCodeException;
import onehajo.seurasaeng.qr.exception.UserNotFoundException;
import onehajo.seurasaeng.qr.repository.QrRepository;
import onehajo.seurasaeng.shuttle.repository.ShuttleRepository;
import onehajo.seurasaeng.user.repository.UserRepository;
import onehajo.seurasaeng.qr.util.AESUtil;
import onehajo.seurasaeng.entity.Boarding;
import onehajo.seurasaeng.entity.Qr;
import onehajo.seurasaeng.entity.Shuttle;
import onehajo.seurasaeng.entity.User;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class QRService {
    private static final int QR_WIDTH = 200;
    private static final int QR_HEIGHT = 200;
    private static final String QR_IMAGE_FORMAT = "png";

    private final AESUtil aesUtil;
    private final S3Service s3Service;
    private final BoardingService boardingService;
    private final UserRepository userRepository;
    private final QrRepository qrRepository;
    private final ShuttleRepository shuttleRepository;
    private ObjectMapper objectMapper = new ObjectMapper();

    /**
     * QR 코드 생성 및 저장
     */
    public void generateQRCode(long user_id, String user_email) throws Exception {
        // 사용자 정보 검증
        User user = validateUserExists(user_id);

        // QR 코드에 포함될 데이터
        String encryptedUserData = createEncryptedQRData(user_id, user_email);
        log.info("encryptedUserData : {}", encryptedUserData);

        // QR 이미지 생성
        byte[] qrImageBytes = generateQRImageBytes(encryptedUserData);

        // S3 QR 이미지 업로드
        String s3Url = s3Service.uploadQRToS3(qrImageBytes);

        // DB에 S3 url 저장
        saveQRToDatabase(user, s3Url);
    }

    private User validateUserExists(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    /**
     * QR 데이터 생성 및 암호화
     */
    private String createEncryptedQRData(Long userId, String userEmail) throws Exception {
        QrReqDTO qrData = new QrReqDTO(userId, userEmail);
        String qrJsonData = objectMapper.writeValueAsString(qrData);
        return aesUtil.encrypt(qrJsonData);
    }

    /**
     * QR 이미지 바이트 배열 생성
     */
    private byte[] generateQRImageBytes(String encryptedData) throws WriterException, IOException {
        Map<EncodeHintType, Object> hints = createQRHints();

        QRCodeWriter qrCodeWriter = new QRCodeWriter();
        BitMatrix bitMatrix = qrCodeWriter.encode(encryptedData, BarcodeFormat.QR_CODE,
                QR_WIDTH, QR_HEIGHT, hints);

        return createQRImageFromBitMatrix(bitMatrix);
    }

    /**
     * QR 생성 힌트 설정
     */
    private Map<EncodeHintType, Object> createQRHints() {
        Map<EncodeHintType, Object> hints = new HashMap<>();
        hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M);
        hints.put(EncodeHintType.CHARACTER_SET, StandardCharsets.UTF_8.name());
        hints.put(EncodeHintType.MARGIN, 1);
        return hints;
    }

    /**
     * BitMatrix -> 이미지 바이트 배열
     */
    private byte[] createQRImageFromBitMatrix(BitMatrix bitMatrix) throws IOException {
        BufferedImage image = new BufferedImage(QR_WIDTH, QR_HEIGHT, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = image.createGraphics();

        graphics.setColor(Color.WHITE);
        graphics.fillRect(0, 0, QR_WIDTH, QR_HEIGHT);

        graphics.setColor(Color.BLACK);
        for (int x = 0; x < QR_WIDTH; x++) {
            for (int y = 0; y < QR_HEIGHT; y++) {
                if (bitMatrix.get(x, y)) {
                    graphics.fillRect(x, y, 1, 1);
                }
            }
        }
        graphics.dispose();

        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            ImageIO.write(image, QR_IMAGE_FORMAT, outputStream);
            return outputStream.toByteArray();
        }
    }

    /**
     * QR 정보 DB 저장
     */
    private void saveQRToDatabase(User user, String s3Url) {
        Qr qr = Qr.builder()
                .user(user)
                .qrCode(s3Url)
                .build();

        qrRepository.save(qr);
    }

    /**
     * user_id로 QR 코드 조회(base64)
     */
    public String getQRCodeByUserId(Long userId) {
        // DB에서 QR 정보 조회
        Qr qr = qrRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("해당 사용자의 QR 코드를 찾을 수 없습니다."));

        // S3에서 이미지 다운로드
        byte[] imageBytes = s3Service.downloadFileFromS3(qr.getQrCode());

        // Base64로 인코딩
        String base64Image = Base64.getEncoder().encodeToString(imageBytes);

        return base64Image;
    }

    /**
     * QR 코드 검증 및 탑승 내역 처리
     */
    public ValidUserResDTO userValidate(String qrCode, Long shuttle_id) throws Exception {
        try {
            // QR 코드 복호화
            QrReqDTO qrRequest = decryptAndParseQRCode(qrCode);

            // 사용자 검증
            User user = validateUser(qrRequest.getUser_id(), qrRequest.getUser_email());

            // 셔틀 정보 조회
            Shuttle shuttle = validateShuttleExists(shuttle_id);
            
            // 중복 탑승자 조회
            boardingService.checkDuplicateBoarding(user.getId(), shuttle_id);

            // QR의 사용자가 유효하다면 -> 사용자의 정보 return & 유효한 사용자의 경우 탑승 내역 저장
            Boarding boardingRecord = boardingService.saveBoardingRecord(qrRequest.getUser_id(), shuttle_id);
            boardingService.incrementBoardingCount(shuttle_id);

            return createValidUserResponse(user, shuttle, boardingRecord);
            } catch (InvalidQRCodeException | UserNotFoundException | IllegalArgumentException e) {
                log.info(e.getMessage());
                throw e;
            } catch (Exception e) {
                log.error("QR 코드 처리 중 오류: ", e);
                throw new IllegalArgumentException("유효하지 않은 QR 코드입니다.");
            }
    }

    /**
     * QR 코드 복호화 및 파싱
     */
    private QrReqDTO decryptAndParseQRCode(String qrCode) throws Exception {
        try {
            String decryptedString = aesUtil.decrypt(qrCode);
            return objectMapper.readValue(decryptedString, QrReqDTO.class);
        } catch (Exception e) {
            log.error("QR 코드 처리 실패: {}", e.getMessage());
            throw new InvalidQRCodeException("유효하지 않은 QR 코드입니다.");
        }
    }

    /**
     * 사용자 검증
     */
    private User validateUser(Long userId, String userEmail) {
        return userRepository.findByIdAndEmail(userId, userEmail)
                .orElseThrow(() -> new UserNotFoundException("유효하지 않은 사용자입니다."));
    }

    /**
     * 셔틀 존재 여부 검증
     */
    private Shuttle validateShuttleExists(Long shuttleId) {
        return shuttleRepository.findById(shuttleId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 셔틀입니다. Shuttle ID: " + shuttleId));
    }

    /**
     * 검증 완료 응답 생성
     */
    private ValidUserResDTO createValidUserResponse(User user, Shuttle shuttle, Boarding boardingRecord) {
        return ValidUserResDTO.builder()
                .user_name(user.getName())
                .boarding_time(boardingRecord.getBoarding_time())
                .departure(shuttle.getDeparture().getLocationName())
                .destination(shuttle.getDestination().getLocationName())
                .build();
    }
}
