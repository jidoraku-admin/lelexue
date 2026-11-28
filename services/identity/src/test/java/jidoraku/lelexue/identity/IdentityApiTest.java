package jidoraku.lelexue.identity;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class IdentityApiTest {

    private static final String TEST_KEY = "test-service-key";
    private static final String VALID_CALLER = "math";

    @Autowired
    private MockMvc mvc;

    @Autowired
    private Flyway flyway;

    private static RequestPostProcessor svc() {
        return headers(VALID_CALLER, TEST_KEY);
    }

    private static RequestPostProcessor headers(String caller, String key) {
        return request -> {
            if (caller != null) {
                request.addHeader("X-Service-Caller", caller);
                request.addHeader("X-Service-Name", caller);
            }
            if (key != null) {
                request.addHeader("X-Service-Key", key);
            }
            return request;
        };
    }

    @BeforeEach
    void resetSchema() {
        flyway.clean();
        flyway.migrate();
    }

    @Test
    void parentCreatesStudentAndSeatsCount() throws Exception {
        mvc.perform(post("/api/identity/parents").with(svc()).contentType(MediaType.APPLICATION_JSON)
                .content("{\"userId\":\"api-p1\"}")).andExpect(status().isCreated());
        mvc.perform(post("/api/identity/parents/api-p1/students").with(svc()).contentType(MediaType.APPLICATION_JSON)
                .content("{\"studentId\":\"api-s1\",\"loginName\":\"apistu1\"}")).andExpect(status().isCreated());
        mvc.perform(get("/api/identity/parents/api-p1/seats").with(svc())).andExpect(jsonPath("$.used").value(1));
    }

    @Test
    void fourthStudentIsRejectedWith400() throws Exception {
        mvc.perform(post("/api/identity/parents").with(svc()).contentType(MediaType.APPLICATION_JSON)
                .content("{\"userId\":\"api-p2\"}"));
        for (int i = 1; i <= 3; i++) {
            mvc.perform(post("/api/identity/parents/api-p2/students").with(svc()).contentType(MediaType.APPLICATION_JSON)
                    .content("{\"studentId\":\"api-p2-s" + i + "\",\"loginName\":\"apip2s" + i + "\"}"));
        }
        mvc.perform(post("/api/identity/parents/api-p2/students").with(svc()).contentType(MediaType.APPLICATION_JSON)
                .content("{\"studentId\":\"api-p2-s4\",\"loginName\":\"apip2s4\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").exists());
    }

    @Test
    void studentInheritsEntitlement() throws Exception {
        mvc.perform(post("/api/identity/parents").with(svc()).contentType(MediaType.APPLICATION_JSON)
                .content("{\"userId\":\"api-p3\"}"));
        mvc.perform(put("/api/identity/parents/api-p3/entitlement").with(svc()).contentType(MediaType.APPLICATION_JSON)
                .content("{\"paid\":true,\"trialActive\":false}")).andExpect(status().isOk());
        mvc.perform(post("/api/identity/parents/api-p3/students").with(svc()).contentType(MediaType.APPLICATION_JSON)
                .content("{\"studentId\":\"api-p3-s1\",\"loginName\":\"apip3s1\"}"));
        mvc.perform(get("/api/identity/accounts/api-p3-s1/entitlement").with(svc()))
                .andExpect(jsonPath("$.active").value(true));
    }

    @Test
    void requestWithoutServiceKeyIsRejected() throws Exception {
        mvc.perform(get("/api/identity/parents/x/seats"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("unauthorized"));
    }

    @Test
    void wrongKeyIsRejected() throws Exception {
        mvc.perform(get("/api/identity/parents/x/seats").with(headers("math", "wrong")))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void keyOfAnotherServiceIsRejected() throws Exception {
        mvc.perform(get("/api/identity/parents/x/seats").with(headers("chinese", TEST_KEY)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void callerNotInAllowListIsRejected() throws Exception {
        mvc.perform(get("/api/identity/parents/x/seats").with(headers("physics", TEST_KEY)))
                .andExpect(status().isUnauthorized());
    }
}