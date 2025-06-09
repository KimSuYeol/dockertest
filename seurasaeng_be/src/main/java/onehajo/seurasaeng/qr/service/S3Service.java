package onehajo.seurasaeng.qr.service;

import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.ObjectMetadata;
import com.amazonaws.services.s3.model.PutObjectRequest;
import com.amazonaws.services.s3.model.S3Object;
import com.amazonaws.services.s3.model.S3ObjectInputStream;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.UUID;

@Slf4j
@Service
public class S3Service {
    private final AmazonS3 amazonS3;

    @Value("${spring.cloud.aws.s3.bucket}")
    private String bucketName;

    public S3Service(AmazonS3 amazonS3) {
        this.amazonS3 = amazonS3;
    }

    public String uploadQRToS3(byte[] qrCode) {
        try {
            String fileName = UUID.randomUUID().toString() + ".png";

            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(qrCode.length);
            metadata.setContentType("image/png");

            amazonS3.putObject(new PutObjectRequest(bucketName, fileName, new ByteArrayInputStream(qrCode), metadata));

            log.info(amazonS3.getUrl(bucketName, fileName).toString());
            return amazonS3.getUrl(bucketName, fileName).toString();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    public byte[] downloadFileFromS3(String s3Url) {
        try {
            // S3 URL 키 추출
            String key = extractKeyFromUrl(s3Url);

            // S3 파일 다운로드
            S3Object s3Object = amazonS3.getObject(bucketName, key);
            S3ObjectInputStream inputStream = s3Object.getObjectContent();

            // InputStream -> byte[]
            return inputStream.readAllBytes();

        } catch (Exception e) {
            log.error("S3 파일 다운로드 실패: {}", s3Url, e);
            throw new RuntimeException("QR 코드 이미지를 가져올 수 없습니다.", e);
        }
    }

    private String extractKeyFromUrl(String s3Url) {
        // S3 URL에서 키 부분만 추출
        try {
            URI uri = new URI(s3Url);
            return uri.getPath().substring(1);
        } catch (URISyntaxException e) {
            throw new RuntimeException("잘못된 S3 URL 형식: " + s3Url, e);
        }
    }
}
