package onehajo.seurasaeng.qr.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.qr.dto.BoardingRecordResDTO;
import onehajo.seurasaeng.qr.repository.BoardingRepository;
import onehajo.seurasaeng.shuttle.repository.ShuttleRepository;
import onehajo.seurasaeng.entity.Boarding;
import onehajo.seurasaeng.entity.Shuttle;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class BoardingService {
    private final RedisTemplate<String, String> redisTemplate;
    private static final String BOARDING_COUNT_KEY_PREFIX = "boarding:count:shuttle:";

    private final BoardingRepository boardingRepository;
    private final ShuttleRepository shuttleRepository;

    /**
     * 탑승 내역 저장
     */
    public Boarding saveBoardingRecord(Long user_id, Long shuttle_id) {
        Shuttle shuttle = shuttleRepository.findById(shuttle_id)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 셔틀입니다."));

        Boarding boardingRecord = Boarding.builder()
                .user_id(user_id)
                .shuttle(shuttle)
                .boarding_time(LocalDateTime.now())
                .build();

        boardingRepository.save(boardingRecord);

        return boardingRecord;
    }

    /**
     * 탑승 내역 조회
     */
    public List<BoardingRecordResDTO> getUserBoardingRecord(Long user_id) {
        List<Boarding> boardingList = boardingRepository.findByUser_idOrderByBoarding_timeDesc(user_id);

        return boardingList.stream()
                .map(this::converToBoardingRecordDTO)
                .collect(Collectors.toList());
    }

    private BoardingRecordResDTO converToBoardingRecordDTO(Boarding boarding) {
        Shuttle shuttle = shuttleRepository.findById(boarding.getShuttle().getId())
                .orElseThrow(() -> new RuntimeException("셔틀 정보를 찾을 수 없습니다."));

        return BoardingRecordResDTO.builder()
                .boarding_id(boarding.getId())
                .departure(shuttle.getDeparture().getLocationName())
                .destination(shuttle.getDestination().getLocationName())
                .boarding_time(boarding.getBoarding_time())
                .build();
    }

    /**
     * 탑승 인원 조회
     */
    public Long getCurrentBoardingCount(Long shuttle_id) {
        try {
            String key = BOARDING_COUNT_KEY_PREFIX + shuttle_id;
            String countStr = redisTemplate.opsForValue().get(key);

            return countStr != null ? Long.parseLong(countStr) : 0L;
        } catch (Exception e) {
            log.error("탑승 인원 조회 실패 - shuttle_id : {}", shuttle_id);
            throw new RuntimeException("탑승 인원 조회 실패", e);
        }
    }

    /**
     * 탑승 인원 추가
     */
    public Long incrementBoardingCount(Long shuttle_id) {
        try {
            String key = BOARDING_COUNT_KEY_PREFIX + shuttle_id;
            Long count = redisTemplate.opsForValue().increment(key);

            log.info("셔틀 {} 탑승인원 증가 : {}", shuttle_id, count);

            return count;
        } catch (Exception e) {
            log.error("탑승 인원 증가 실패 - 노선 ID : {}", shuttle_id);

            throw new RuntimeException("탑승 인원 증가 실패.", e);
        }
    }

    /**
     * 탑승 인원 초기화
     */
    public void resetBoardingCount(Long shuttle_id) {
        try {
            String key = BOARDING_COUNT_KEY_PREFIX + shuttle_id;
            redisTemplate.delete(key);

            log.info("탑승 인원 삭제 - shuttle_id : {}", shuttle_id);
        } catch (Exception e) {
            log.error("탑승 인원 삭제 실패 - shuttle_id : {}", shuttle_id);
            throw new RuntimeException("탑승 인원 삭제 실패", e);
        }
    }

    /**
     * 중복 탑승 체크
     */
    public void checkDuplicateBoarding(Long userId, Long shuttleId) {
        LocalDate today = LocalDate.now();
        LocalDateTime todayStart = today.atStartOfDay();
        LocalDateTime todayEnd = today.plusDays(1).atStartOfDay();

        boolean alreadyBoardedToday = boardingRepository
                .existsByUser_idAndShuttleIdAndBoarding_timeBetween(
                        userId, shuttleId, todayStart, todayEnd);

        if (alreadyBoardedToday) {
            throw new IllegalArgumentException("오늘 이미 해당 셔틀에 탑승하셨습니다.");
        }
    }
}
