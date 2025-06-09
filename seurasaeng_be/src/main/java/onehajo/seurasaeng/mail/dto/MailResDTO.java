package onehajo.seurasaeng.mail.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MailResDTO {
    private String mailFrom;
    private String mailTo;
    private String mailCc;
    private String mailBcc;
    private String mailSubject;
    private String mailContent;
    private String contentType;

    public MailResDTO() {
        contentType = "text/plain";
    }

}
