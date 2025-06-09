package onehajo.seurasaeng.socket.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.socket.dto.EndMessagePayloadDTO;
import onehajo.seurasaeng.socket.dto.MessagePayloadDTO;
import onehajo.seurasaeng.socket.exception.EndRouteException;
import onehajo.seurasaeng.socket.exception.MessageSendException;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class BusRouteService {

    // WebSocket 메시지 송신을 위한 템플릿
    private final SimpMessagingTemplate messagingTemplate;

    public void broadcastGps(Long routeId, MessagePayloadDTO payload) {
        log.info("GPS 수신: {}", payload);

        try {
            messagingTemplate.convertAndSend("/topic/route/" + routeId, payload);
        } catch (Exception e) {
            log.error("메시지 브로커 전송 실패: {}", e.getMessage(), e);
            throw new MessageSendException("메시지 전송 중 오류가 발생했습니다.");
        }
    }

    public void endRoute(Long routeId) {
        log.info("운행 종료 요청 수신: routeId={}", routeId);

        try {
            EndMessagePayloadDTO endMessage = EndMessagePayloadDTO.create();
            messagingTemplate.convertAndSend("/topic/route/" + routeId, endMessage);
        } catch (Exception e) {
            log.error("운행 종료 메시지 전송 실패: {}", e.getMessage(), e);
            throw new EndRouteException("운행 종료 알림 중 오류가 발생했습니다.");
        }
    }
}