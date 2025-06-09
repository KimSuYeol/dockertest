package onehajo.seurasaeng.qr.exception;

public class InvalidQRCodeException extends RuntimeException {
    public InvalidQRCodeException(String message) {
        super(message);
    }
}