package jidoraku.lelexue.identity;

/** 权益，挂在母账号上；学生继承母账号的权益。 */
public record Entitlement(boolean paid, boolean trialActive) {

    public static final Entitlement NONE = new Entitlement(false, false);

    public boolean active() {
        return paid || trialActive;
    }
}
