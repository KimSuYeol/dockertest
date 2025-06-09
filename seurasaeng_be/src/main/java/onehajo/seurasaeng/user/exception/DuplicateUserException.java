package onehajo.seurasaeng.user.exception;

public class DuplicateUserException extends IllegalArgumentException {
    public DuplicateUserException(String message) {
        super(message);
    }
}