package onehajo.seurasaeng.shuttle.exception;

public class ShuttleNotFoundException extends RuntimeException {
    public ShuttleNotFoundException(Long shuttleId) {
        super("해당 셔틀 노선을 찾을 수 없습니다. ID=" + shuttleId);
    }
}