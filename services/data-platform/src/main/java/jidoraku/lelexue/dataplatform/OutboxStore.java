package jidoraku.lelexue.dataplatform;

import java.time.Instant;
import java.util.List;

/**
 * 发件箱存储（方案 C，见草案第 5 节）。第一切片用内存实现，后续替换为库内表，语义保持不变。
 */
public interface OutboxStore {

    /** 与业务写入同一事务写入一条待发布事件。重复 eventId 不重复写入。 */
    void append(MasteryChangedEvent event, Instant now);

    /** 取出待发布记录（按 createdAt 升序，未发布且未进入死信）。 */
    List<OutboxRecord> pending(int limit);

    void markSent(String eventId, Instant now);

    /** 记录一次失败；超过最大次数则进入死信。 */
    void markFailed(String eventId, String reason, int maxAttempts, Instant now);

    /** 按保留期清理：已发布事件保留 7 天，死信保留 30 天。 */
    void purge(Instant now);

    List<OutboxRecord> deadLetters();
}
