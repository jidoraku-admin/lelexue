package jidoraku.lelexue.dataplatform;

/** 消费端入口：返回 true 表示产生一次「首次达到」的经验发放。 */
public interface ConsumerGate {
    boolean accept(MasteryChangedEvent event);
}
