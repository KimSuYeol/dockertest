package onehajo.seurasaeng.shuttle.repository;

import onehajo.seurasaeng.entity.Shuttle;
import onehajo.seurasaeng.entity.Timetable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TimetableRepository extends JpaRepository<Timetable, Long> {
    List<Timetable> findByShuttleOrderByDepartureTimeAsc(Shuttle shuttle);
    void deleteByShuttle(Shuttle shuttle);
}
