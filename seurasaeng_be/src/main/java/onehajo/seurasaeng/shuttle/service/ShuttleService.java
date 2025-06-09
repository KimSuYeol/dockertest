package onehajo.seurasaeng.shuttle.service;

import lombok.RequiredArgsConstructor;
import onehajo.seurasaeng.entity.Shuttle;
import onehajo.seurasaeng.shuttle.dto.ShuttleResponseDto;
import onehajo.seurasaeng.shuttle.dto.ShuttleWithLocationResponseDto;
import onehajo.seurasaeng.shuttle.repository.ShuttleRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ShuttleService {
    private final ShuttleRepository shuttleRepository;

    public List<ShuttleResponseDto> getShuttleList() {
        List<Shuttle> shuttles = shuttleRepository.findAll();

        return shuttles.stream()
                .map(shuttle -> ShuttleResponseDto.builder()
                        .id(shuttle.getId())
                        .shuttleName(shuttle.getShuttleName())
                        .departureName(shuttle.getDeparture().getLocationName())
                        .destinationName(shuttle.getDestination().getLocationName())
                        .commute(shuttle.getIsCommute())
                        .build())
                .toList();
    }

    public List<ShuttleWithLocationResponseDto> getShuttleWithLocation() {
        List<Shuttle> shuttles = shuttleRepository.findAll();

        return shuttles.stream()
                .map(shuttle -> ShuttleWithLocationResponseDto.builder()
                        .id(shuttle.getId())
                        .shuttleName(shuttle.getShuttleName())
                        .departureName(shuttle.getDeparture().getLocationName())
                        .departureLongitude(shuttle.getDeparture().getLongitude())
                        .departureLatitude(shuttle.getDeparture().getLatitude())
                        .destinationName(shuttle.getDestination().getLocationName())
                        .destinationLongitude(shuttle.getDestination().getLongitude())
                        .destinationLatitude(shuttle.getDestination().getLatitude())
                        .commute(shuttle.getIsCommute())
                        .build())
                .toList();
    }
}
