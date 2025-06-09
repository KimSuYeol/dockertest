package onehajo.seurasaeng.shuttle.controller;

import lombok.RequiredArgsConstructor;
import onehajo.seurasaeng.shuttle.dto.ShuttleResponseDto;
import onehajo.seurasaeng.shuttle.dto.ShuttleWithLocationResponseDto;
import onehajo.seurasaeng.shuttle.service.ShuttleService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/shuttles")
public class ShuttleController {
    private final ShuttleService shuttleService;

    @GetMapping
    public ResponseEntity<List<ShuttleResponseDto>> getShuttles() {
        List<ShuttleResponseDto> shuttleList = shuttleService.getShuttleList();
        if (shuttleList.isEmpty()) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(shuttleList);
    }

    @GetMapping("/locations")
    public ResponseEntity<List<ShuttleWithLocationResponseDto>> getShuttlesWithLocation() {
        List<ShuttleWithLocationResponseDto> shuttleList = shuttleService.getShuttleWithLocation();
        if (shuttleList.isEmpty()) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(shuttleList);
    }
}
