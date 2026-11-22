package jidoraku.lelexue.dataplatform;

import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 知识点编码（共通 v1，docs/architecture/shared/README.md 第 1.5 节）。
 * 格式：{@code <subject>.g<grade>.v<volume>.u<unit>.k<seq>}，全部小写，例如 {@code math.g3.v1.u01.k001}。
 */
public record KnowledgePointId(String value) {

    private static final Pattern PATTERN =
            Pattern.compile("^([a-z]+)\\.g(\\d{1,2})\\.v([12])\\.u(\\d{2})\\.k(\\d{3})$");

    public KnowledgePointId {
        Objects.requireNonNull(value, "knowledgePointId");
        Matcher m = PATTERN.matcher(value);
        if (!m.matches()) {
            throw new IllegalArgumentException("knowledgePointId 格式不符合共通 v1: " + value);
        }
        int grade = Integer.parseInt(m.group(2));
        if (grade < 1 || grade > 12) {
            throw new IllegalArgumentException("grade 必须在 1–12 之间: " + value);
        }
        if (Integer.parseInt(m.group(4)) < 1 || Integer.parseInt(m.group(5)) < 1) {
            throw new IllegalArgumentException("unit 与 seq 从 1 开始编号: " + value);
        }
    }

    /** 编码中的学科部分，应与事件的 subject 一致。 */
    public String subject() {
        return value.substring(0, value.indexOf('.'));
    }
}
