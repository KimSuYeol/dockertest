package onehajo.seurasaeng.shuttle.exception;

public class InvalidTimetableSizeException extends RuntimeException {
    public InvalidTimetableSizeException() {
        super("기존 시간표 개수와 요청한 시간표 개수가 다릅니다.");
    }
}