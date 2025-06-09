package onehajo.seurasaeng.shuttle.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import onehajo.seurasaeng.shuttle.dto.TimetableResponseDto;
import onehajo.seurasaeng.shuttle.dto.UpdateTimetableRequestDto;
import onehajo.seurasaeng.shuttle.service.TimetableService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class TimetableController {

    private final TimetableService timetableService;

    @GetMapping("/timetables")
    public ResponseEntity<TimetableResponseDto> getTimetable() {
        TimetableResponseDto response = timetableService.getTimetable();

        if ((response.getCommute() == null || response.getCommute().isEmpty()) &&
                (response.getOffwork() == null || response.getOffwork().isEmpty())) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(response);
    }

    @PutMapping("/timetable")
    public ResponseEntity<Void> updateTimetable(@RequestBody @Valid UpdateTimetableRequestDto request) {
        timetableService.updateTimetable(request);
        return ResponseEntity.ok().build();
    }
}