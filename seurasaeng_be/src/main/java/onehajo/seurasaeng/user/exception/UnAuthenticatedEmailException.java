package onehajo.seurasaeng.user.exception;

public class UnAuthenticatedEmailException extends IllegalArgumentException {
    public UnAuthenticatedEmailException(String message) {
        super(message);
    }
}