package onehajo.seurasaeng.config;

import lombok.RequiredArgsConstructor;
import onehajo.seurasaeng.socket.security.JwtChannelInterceptor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private static final String ENDPOINT = "/ws";
    private static final String SIMPLE_BROKER = "/topic";
    private static final String PUBLISH = "/app";

    private final JwtChannelInterceptor jwtChannelInterceptor;

    @Value("${cors.allowed-origins}")
    private String[] allowedOrigins;

    /**
     * WebSocket 연결 Endpoint 등록
     * 클라이언트는 해당 Endpoint를 통해 WebSocket 연결을 초기화.
     *
     * @param registry StompEndpointRegistry
     */
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint(ENDPOINT)
                .setAllowedOriginPatterns(allowedOrigins);
    }

    /**
     * 메시지 브로커 구성
     * 클라이언트가 메시지를 보내는 경로와 클라이언트가 구독하는 경로를 설정.
     *
     * @param registry MessageBrokerRegistry
     */
    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker(SIMPLE_BROKER); // 클라이언트 구독 주소 prefix
        registry.setApplicationDestinationPrefixes(PUBLISH); // 클라이언트 송신 주소 prefix
    }

    /**
     * 클라이언트에서 수신하는 WebSocket 메시지 처리 채널에 JWT 인증 인터셉터 추가
     * 인터셉터를 통해 WebSocket 메시지 전송 전에 인증/인가 처리 수행.
     *
     * @param registration ChannelRegistration
     */
    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(jwtChannelInterceptor);
    }
}