package onehajo.seurasaeng.socket.handler;

import lombok.extern.slf4j.Slf4j;
import onehajo.seurasaeng.socket.exception.EndRouteException;
import onehajo.seurasaeng.socket.exception.MessageSendException;
import org.springframework.messaging.handler.annotation.MessageExceptionHandler;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.stereotype.Controller;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Controller
public class WebSocketExceptionHandler {

    /**
     * 일반적인 IllegalArgumentException
     */
    @MessageExceptionHandler(Exception.class)
    @SendToUser("/queue/errors")
    public Map<String, String> handleGenericException(Exception ex) {
        return Map.of("message", "서버 오류가 발생했습니다.");
    }

    @MessageExceptionHandler(MethodArgumentNotValidException.class)
    @SendToUser("/queue/errors")
    public Map<String, String> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });
        return errors;
    }

    @MessageExceptionHandler(EndRouteException.class)
    @SendToUser("/queue/errors")
    public Map<String, String> handleEndRouteException(EndRouteException e) {
        return Map.of("message", e.getMessage());
    }

    @MessageExceptionHandler(MessageSendException.class)
    @SendToUser("/queue/errors")
    public Map<String, String> handleMessageSendException(MessageSendException e) {
        return Map.of("message", e.getMessage());
    }
}