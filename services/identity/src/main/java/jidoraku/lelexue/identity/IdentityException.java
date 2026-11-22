package jidoraku.lelexue.identity;

/** 身份服务的业务错误（规则违反或账号不存在）。 */
public class IdentityException extends RuntimeException {

    public IdentityException(String message) {
        super(message);
    }
}
