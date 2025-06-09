package onehajo.seurasaeng.socket.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.socket.dto.MessagePayloadDTO;
import onehajo.seurasaeng.socket.service.BusRouteService;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/route")
@RequiredArgsConstructor
public class BusRouteController {

    private final BusRouteService busRouteService;

    /**
     *  실시간 GPS 데이터 수신 후 브로드캐스트.
     * 클라이언트가 STOMP SEND로 위치 데이터를 전송하면
     * 서버는 구독자들에게 실시간 위치를 브로드캐스트.
     *
     * @param routeId  노선 ID (STOMP destination 경로 변수)
     * @param payload  클라이언트로부터 수신한 GPS 위치 데이터
     */
    @MessageMapping("/route/{routeId}")
    public void broadcastGps(@DestinationVariable Long routeId, @Valid MessagePayloadDTO payload) {
        busRouteService.broadcastGps(routeId, payload);
    }

    /**
     * 운행 종료 API
     * 서버는 운행 종료 신호를 WebSocket 브로드캐스트하여
     * 모든 구독자에게 운행 종료를 알림.
     *
     * @param routeId  종료할 노선 ID
     */
    @PostMapping("/{routeId}/end")
    public void endRoute(@PathVariable Long routeId) {
        busRouteService.endRoute(routeId);
    }
}