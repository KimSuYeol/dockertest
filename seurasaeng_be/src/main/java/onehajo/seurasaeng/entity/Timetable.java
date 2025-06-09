package onehajo.seurasaeng.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Entity
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "timetable", schema = "seurasaeng_test")
public class Timetable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "timetable_id")
    private Long id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shuttle_id")
    private Shuttle shuttle;

    @NotNull
    @Column(name = "departure_time", columnDefinition = "TIME")
    private LocalTime departureTime;

    @NotNull
    @Column(name = "boarding_location", columnDefinition = "VARCHAR(100)")
    private String boardingLocation;

    @NotNull
    @Column(name = "dropoff_location", columnDefinition = "VARCHAR(100)")
    private String dropoffLocation;

    @Column(name = "arrival_minutes", columnDefinition = "INTEGER")
    private Integer arrivalMinutes;

    @Column(name = "total_seats", columnDefinition = "INTEGER")
    private Integer totalSeats;

    public void updateDepartureTime(LocalTime newTime) {
        this.departureTime = newTime;
    }
}