package com.cn.ycm.gateway.swagger;

import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * Created by ycm.
 * Created on 2020/7/16 下午10:39.
 * Description: Swagger 拦截器
 */
@Component
public class SwaggerHeaderGatewayFilter extends AbstractGatewayFilterFactory {

    @Override
    public GatewayFilter apply(Object config) {
        return (exchange, chain) -> {
            ServerHttpRequest request = exchange.getRequest();
            String path = request.getURI().getPath();
            if(!StringUtils.endsWithIgnoreCase(path, SwaggerResources.API_URI)) {
                return chain.filter(exchange);
            }

            String basePath = path.substring(0, path.lastIndexOf(SwaggerResources.API_URI));
            ServerHttpRequest newRequest = request.mutate().header("X-Forwarded-Prefix", basePath).build();
            return chain.filter(exchange.mutate().request(newRequest).build());
        };
    }
}
