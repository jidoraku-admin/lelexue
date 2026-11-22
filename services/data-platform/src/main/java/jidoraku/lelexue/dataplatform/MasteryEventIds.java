package jidoraku.lelexue.dataplatform;

/** eventId 由数据平台生成（#92 裁定）：{@code <subject>:<userId>:<knowledgePointId>:<level>}。同一业务键得到同一值。 */
public final class MasteryEventIds {

    /** outbox_event.event_id 与消费端表的列宽（V2 迁移后）。 */
    public static final int MAX_LENGTH = 128;

    private MasteryEventIds() {
    }

    public static String of(String subject, String userId, KnowledgePointId kp, int level) {
        String id = subject + ":" + userId + ":" + kp.value() + ":" + level;
        if (id.length() > MAX_LENGTH) {
            throw new IllegalArgumentException("eventId 超过 " + MAX_LENGTH + " 字符: " + id.length());
        }
        return id;
    }
}
