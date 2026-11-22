package jidoraku.lelexue.dataplatform;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * 消费端去重：eventId 去重（至少一次投递），业务唯一键保证经验只发放一次。
 */
public final class ConsumerDedupe {

    private final Set<String> seenEventIds = new HashSet<>();
    private final Set<List<String>> grantedKeys = new HashSet<>();

    /**
     * 处理一条事件。返回 true 表示产生了一次「首次达到」的经验发放。
     * 同一 eventId 重复投递、或同一业务唯一键再次到达，都不会再次发放。
     */
    public synchronized boolean accept(MasteryChangedEvent event) {
        if (!seenEventIds.add(event.eventId())) {
            return false;
        }
        return grantedKeys.add(event.businessKey());
    }
}
