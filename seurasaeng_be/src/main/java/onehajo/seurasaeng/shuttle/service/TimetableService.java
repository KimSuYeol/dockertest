package onehajo.seurasaeng.shuttle.service;

import jakarta.persistence.EntityNotFoundException;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import onehajo.seurasaeng.entity.Shuttle;
import onehajo.seurasaeng.entity.Timetable;
import onehajo.seurasaeng.shuttle.dto.ShuttleWithTimetableDto;
import onehajo.seurasaeng.shuttle.dto.TimetableDto;
import onehajo.seurasaeng.shuttle.dto.TimetableResponseDto;
import onehajo.seurasaeng.shuttle.dto.UpdateTimetableRequestDto;
import onehajo.seurasaeng.shuttle.exception.InvalidTimetableSizeException;
import onehajo.seurasaeng.shuttle.exception.ShuttleNotFoundException;
import onehajo.seurasaeng.shuttle.repository.ShuttleRepository;
import onehajo.seurasaeng.shuttle.repository.TimetableRepository;
import org.springframework.stereotype.Service;

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TimetableService {

    private final ShuttleRepository shuttleRepository;
    private final TimetableRepository timetableRepository;

    public TimetableResponseDto getTimetable() {
        List<ShuttleWithTimetableDto> commuteShuttles = buildTimetableList(true); // 출근 셔틀 목록
        List<ShuttleWithTimetableDto> offworkShuttles = buildTimetableList(false); // 퇴근 셔틀 목록

        return TimetableResponseDto.builder()
                .commute(commuteShuttles)
                .offwork(offworkShuttles)
                .build();
    }

    private List<ShuttleWithTimetableDto> buildTimetableList(boolean isCommute) {
        // 출근 또는 퇴근 셔틀 조회
        List<Shuttle> shuttles = shuttleRepository.findByIsCommute(isCommute);
        List<ShuttleWithTimetableDto> shuttleWithTimetableDtoList = new ArrayList<>();

        for (Shuttle shuttle : shuttles) {
            List<Timetable> timetables = timetableRepository.findByShuttleOrderByDepartureTimeAsc(shuttle);

            // 시간표가 없으면 건너뜀
            if (timetables == null || timetables.isEmpty()) {
                continue;
            }

            Timetable firstTimetable = timetables.getFirst(); // 첫 번째 시간표

            // 출근이면 출발지, 퇴근이면 도착지
            String spotName = "";
            if (isCommute) {
                spotName = shuttle.getDeparture().getLocationName();
            } else {
                spotName = shuttle.getDestination().getLocationName();
            }

            // 출근이면 boardingLocation, 퇴근이면 dropoffLocation
            String boardingPoint = "";
            if (isCommute) {
                boardingPoint = firstTimetable.getBoardingLocation();
            } else {
                boardingPoint = firstTimetable.getDropoffLocation();
            }

            // 시간표 DTO 변환
            List<TimetableDto> timetableDtos = new ArrayList<>();
            for (int i = 0; i < timetables.size(); i++) {
                Timetable timetable = timetables.get(i);

                TimetableDto timetableDto = TimetableDto.builder()
                        .turn((i + 1) + "회") // 1회, 2회 형식
                        .departureTime(timetable.getDepartureTime().toString().substring(0, 5)) // "HH:mm" 포맷
                        .build();

                timetableDtos.add(timetableDto);
            }

            // 셔틀 + 시간표 DTO 구성
            ShuttleWithTimetableDto shuttleWithTimetableDto = ShuttleWithTimetableDto.builder()
                    .shuttleId(shuttle.getId())
                    .shuttleName(shuttle.getShuttleName())
                    .spotName(spotName)
                    .duration(formatDuration(firstTimetable.getArrivalMinutes()))
                    .totalSeats(formatTotalSeats(firstTimetable.getTotalSeats()))
                    .boardingPoint(boardingPoint)
                    .timetables(timetableDtos)
                    .build();

            shuttleWithTimetableDtoList.add(shuttleWithTimetableDto);
        }

        return shuttleWithTimetableDtoList;
    }

    @Transactional
    public void updateTimetable(UpdateTimetableRequestDto request) {
        Shuttle shuttle = shuttleRepository.findById(request.getShuttleId())
                .orElseThrow(() -> new ShuttleNotFoundException(request.getShuttleId()));

        // 기존 시간표 조회 (departureTime 오름차순 정렬)
        List<Timetable> timetables = timetableRepository.findByShuttleOrderByDepartureTimeAsc(shuttle);

        // 요청 받은 시간표 리스트
        List<UpdateTimetableRequestDto.TimetableDto> newTimetables = request.getTimetables();

        if (timetables.size() != newTimetables.size()) {
            throw new InvalidTimetableSizeException();
        }

        for (int i = 0; i < timetables.size(); i++) {
            Timetable timetable = timetables.get(i);
            UpdateTimetableRequestDto.TimetableDto dto = newTimetables.get(i);

            // 시간만 업데이트
            timetable.updateDepartureTime(LocalTime.parse(dto.getDepartureTime()));
        }

        // 저장
        timetableRepository.saveAll(timetables);
    }

    private String formatDuration(Integer minutes) {
        if (minutes == null) {
            return "";
        }
        return minutes + "분";
    }

    private String formatTotalSeats(Integer seats) {
        if (seats == null) {
            return "";
        }
        return seats + "명";
    }
}