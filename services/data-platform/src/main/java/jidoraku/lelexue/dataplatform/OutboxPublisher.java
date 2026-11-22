package jidoraku.lelexue.dataplatform;

import java.time.Clock;
import java.util.function.Consumer;

/**
 * 轮询发布（至少一次）：投递成功才标记为已发布；失败累计，超过上限进入死信，由数据平台负责人查看。
 */
public final class OutboxPublisher {

    private final OutboxStore store;
    private final Consumer<MasteryChangedEvent> transport;
    private final int batchSize;
    private final int maxAttempts;
    private final Clock clock;

    public OutboxPublisher(OutboxStore store, Consumer<MasteryChangedEvent> transport,
                           int batchSize, int maxAttempts, Clock clock) {
        if (batchSize < 1 || maxAttempts < 1) {
            throw new IllegalArgumentException("batchSize 与 maxAttempts 必须大于 0");
        }
        this.store = store;
        this.transport = transport;
        this.batchSize = batchSize;
        this.maxAttempts = maxAttempts;
        this.clock = clock;
    }

    /** 执行一轮，返回本轮成功投递的条数。 */
    public int pollOnce() {
        int sent = 0;
        for (OutboxRecord r : store.pending(batchSize)) {
            try {
                transport.accept(r.event());
                store.markSent(r.event().eventId(), clock.instant());
                sent++;
            } catch (RuntimeException e) {
                store.markFailed(r.event().eventId(), String.valueOf(e.getMessage()), maxAttempts, clock.instant());
            }
        }
        return sent;
    }
}
