package jidoraku.lelexue.identity;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.env.Environment;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Locale;
import java.util.Set;
import java.util.concurrent.atomic.AtomicLong;
import java.util.regex.Pattern;

/**
 * 服务间鉴权：每个服务一把密钥（0015 第一条，ai-gateway §8）。
 *
 * <p>调用方在请求头 {@value #CALLER_HEADER} 写自己的服务名（如 {@code math}），
 * 在 {@value #KEY_HEADER} 写自己的密钥。密钥只从部署环境的环境变量
 * {@code LELEXUE_SVC_KEY_<服务名大写>} 读取，不入仓库、不写入代码。
 * 调用方不在名单、缺少请求头、环境中没有该服务的密钥、密钥不一致，一律拒绝（401），
 * 只记录拒绝次数，不记录请求内容与密钥。
 */
public class ServiceKeyFilter extends OncePerRequestFilter {

    public static final String CALLER_HEADER = "X-Lelexue-Caller";
    public static final String KEY_HEADER = "X-Lelexue-Service-Key";
    public static final String ENV_PREFIX = "LELEXUE_SVC_KEY_";

    private static final Logger log = LoggerFactory.getLogger(ServiceKeyFilter.class);
    private static final Pattern CALLER_NAME = Pattern.compile("^[a-z][a-z0-9-]{0,31}$");

    private final Environment env;
    private final Set<String> allowedCallers;
    private final AtomicLong rejected = new AtomicLong();

    public ServiceKeyFilter(Environment env, Set<String> allowedCallers) {
        this.env = env;
        this.allowedCallers = Set.copyOf(allowedCallers);
    }

    /** 服务名对应的环境变量名，例如 {@code data-platform} → {@code LELEXUE_SVC_KEY_DATA_PLATFORM}。 */
    public static String envName(String caller) {
        return ENV_PREFIX + caller.toUpperCase(Locale.ROOT).replace('-', '_');
    }

    /** 启动以来的拒绝次数。 */
    public long rejectedCount() {
        return rejected.get();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        if (isAuthorized(request.getHeader(CALLER_HEADER), request.getHeader(KEY_HEADER))) {
            chain.doFilter(request, response);
            return;
        }
        long n = rejected.incrementAndGet();
        log.warn("service key rejected, total={}", n);
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.setCharacterEncoding(StandardCharsets.UTF_8.name());
        response.getWriter().write("{\"error\":\"unauthorized\"}");
    }

    boolean isAuthorized(String caller, String presentedKey) {
        if (caller == null || presentedKey == null || presentedKey.isEmpty()) {
            return false;
        }
        if (!CALLER_NAME.matcher(caller).matches() || !allowedCallers.contains(caller)) {
            return false;
        }
        String expected = env.getProperty(envName(caller));
        if (expected == null || expected.isBlank()) {
            return false;
        }
        return MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8),
                presentedKey.getBytes(StandardCharsets.UTF_8));
    }
}
