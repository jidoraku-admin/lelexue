package jidoraku.lelexue.identity;

import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** 服务密钥校验的单元测试，不依赖数据库（0015 第一条）。 */
class ServiceKeyFilterTest {

    private final MockEnvironment env = new MockEnvironment()
            .withProperty("LELEXUE_SVC_KEY_MATH", "k-math")
            .withProperty("LELEXUE_SVC_KEY_DATA_PLATFORM", "k-dp")
            .withProperty("LELEXUE_SVC_KEY_CHINESE", " ");
    private final ServiceKeyFilter filter =
            new ServiceKeyFilter(env, Set.of("math", "chinese", "data-platform"));

    @Test
    void envNameMapsDashToUnderscore() {
        assertEquals("LELEXUE_SVC_KEY_MATH", ServiceKeyFilter.envName("math"));
        assertEquals("LELEXUE_SVC_KEY_DATA_PLATFORM", ServiceKeyFilter.envName("data-platform"));
    }

    @Test
    void acceptsMatchingKeyOnly() {
        assertTrue(filter.isAuthorized("math", "k-math"));
        assertTrue(filter.isAuthorized("data-platform", "k-dp"));
        assertFalse(filter.isAuthorized("math", "k-dp"));
        assertFalse(filter.isAuthorized("data-platform", "k-math"));
    }

    @Test
    void rejectsMissingOrBlankValues() {
        assertFalse(filter.isAuthorized(null, "k-math"));
        assertFalse(filter.isAuthorized("math", null));
        assertFalse(filter.isAuthorized("math", ""));
        assertFalse(filter.isAuthorized("chinese", " "), "环境里的空白密钥视为未配置");
    }

    @Test
    void rejectsUnknownOrMalformedCaller() {
        assertFalse(filter.isAuthorized("physics", "k-math"), "不在名单内");
        assertFalse(filter.isAuthorized("MATH", "k-math"), "服务名只收小写");
        assertFalse(filter.isAuthorized("../math", "k-math"));
    }

    @Test
    void rejectedRequestGets401AndIsCounted() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/identity/parents/p/seats");
        req.addHeader(ServiceKeyFilter.CALLER_HEADER, "math");
        req.addHeader(ServiceKeyFilter.KEY_HEADER, "wrong");
        MockHttpServletResponse res = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(req, res, chain);

        assertEquals(401, res.getStatus());
        assertNull(chain.getRequest(), "被拒绝的请求不进入后续处理");
        assertEquals(1, filter.rejectedCount());
        assertFalse(res.getContentAsString().contains("wrong"), "响应里不回显密钥");
    }

    @Test
    void acceptedRequestPassesThrough() throws Exception {
        MockHttpServletRequest req = new MockHttpServletRequest("GET", "/api/identity/parents/p/seats");
        req.addHeader(ServiceKeyFilter.CALLER_HEADER, "math");
        req.addHeader(ServiceKeyFilter.KEY_HEADER, "k-math");
        MockHttpServletResponse res = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(req, res, chain);

        assertEquals(200, res.getStatus());
        assertNotNull(chain.getRequest());
        assertEquals(0, filter.rejectedCount());
    }
}