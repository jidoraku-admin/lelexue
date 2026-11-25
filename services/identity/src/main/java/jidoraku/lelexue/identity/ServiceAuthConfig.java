package jidoraku.lelexue.identity;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.Set;

/** 把服务密钥校验挂到身份服务的全部接口（/api/identity/*）。 */
@Configuration
public class ServiceAuthConfig {

    @Bean
    public ServiceKeyFilter serviceKeyFilter(
            Environment env,
            @Value("${identity.allowed-callers:english,math,chinese,physics,chemistry}") String callers) {
        Set<String> allowed = new LinkedHashSet<>();
        Arrays.stream(callers.split(",")).map(String::trim).filter(s -> !s.isEmpty()).forEach(allowed::add);
        return new ServiceKeyFilter(env, allowed);
    }

    @Bean
    public FilterRegistrationBean<ServiceKeyFilter> serviceKeyFilterRegistration(ServiceKeyFilter filter) {
        FilterRegistrationBean<ServiceKeyFilter> reg = new FilterRegistrationBean<>(filter);
        reg.addUrlPatterns("/api/identity/*");
        reg.setOrder(0);
        return reg;
    }
}
