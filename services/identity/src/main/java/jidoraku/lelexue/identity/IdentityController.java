package jidoraku.lelexue.identity;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.Map;

/** 身份服务的内网接口（#23）。仅内网可达，服务间调用须带服务密钥（ai-gateway §8、0015 第一条，见 ServiceKeyFilter）。 */
@RestController
@RequestMapping("/api/identity")
public class IdentityController {

    public record RegisterParentRequest(String userId, Integer seatLimit) {}
    public record CreateStudentRequest(String studentId, String loginName) {}
    public record EntitlementRequest(boolean paid, boolean trialActive) {}
    public record EntitlementResponse(boolean paid, boolean trialActive, boolean active) {}

    private final IdentityService service;

    public IdentityController(IdentityService service) {
        this.service = service;
    }

    @PostMapping("/parents")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, String> registerParent(@RequestBody RegisterParentRequest body) {
        service.registerParent(body.userId(), body.seatLimit());
        return Map.of("userId", body.userId());
    }

    @PostMapping("/parents/{parentId}/students")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, String> createStudent(@PathVariable String parentId, @RequestBody CreateStudentRequest body) {
        service.createStudent(parentId, body.studentId(), body.loginName());
        return Map.of("userId", body.studentId());
    }

    @PostMapping("/parents/{parentId}/students/{studentId}/unlink")
    public Map<String, String> unlink(@PathVariable String parentId, @PathVariable String studentId) {
        service.unlink(parentId, studentId);
        return Map.of("studentId", studentId);
    }

    @GetMapping("/parents/{parentId}/seats")
    public Map<String, Integer> seats(@PathVariable String parentId) {
        return Map.of("used", service.seatsUsed(parentId));
    }

    @PutMapping("/parents/{parentId}/entitlement")
    public Map<String, String> setEntitlement(@PathVariable String parentId, @RequestBody EntitlementRequest body) {
        service.setEntitlement(parentId, new Entitlement(body.paid(), body.trialActive()));
        return Map.of("parentId", parentId);
    }

    @GetMapping("/accounts/{userId}/entitlement")
    public EntitlementResponse entitlement(@PathVariable String userId) {
        Entitlement e = service.getEntitlement(userId);
        return new EntitlementResponse(e.paid(), e.trialActive(), e.active());
    }

    @ExceptionHandler(IdentityException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Map<String, String> onError(IdentityException e) {
        return Map.of("error", e.getMessage());
    }
}
