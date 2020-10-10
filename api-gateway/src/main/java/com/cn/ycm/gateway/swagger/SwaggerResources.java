package com.cn.ycm.gateway.swagger;

import lombok.AllArgsConstructor;
import org.springframework.cloud.gateway.config.GatewayProperties;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.support.NameUtils;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;
import springfox.documentation.swagger.web.SwaggerResource;
import springfox.documentation.swagger.web.SwaggerResourcesProvider;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by ycm.
 * Created on 2020/10/02 下午10:39.
 * Description: 因为Swagger暂不支持webflux项目，所以Gateway里不能配置SwaggerConfig，也就是说Gateway无法提供自身API。
 * 配置SwaggerProvider，获取Api-doc，即SwaggerResources
 * SwaggerResources 相当于业务逻辑层
 */
@Service
@Primary
@AllArgsConstructor
public class SwaggerResources implements SwaggerResourcesProvider {

    private final RouteLocator routeLocator;
    private final GatewayProperties gatewayProperties;

    public static final String SWAGGER_VERSION = "2.0";
    public static final String API_URI = "/v2/api-docs";

    @Override
    public List<SwaggerResource> get() {
        List<SwaggerResource> resources = new ArrayList<>();
        List<String> routes = new ArrayList<>();
        // 获取所有的路由信息
        routeLocator.getRoutes().subscribe(route -> routes.add(route.getId()));
        gatewayProperties.getRoutes().stream()
                .filter(routeDefinition -> routes.contains(routeDefinition.getId()))
                .forEach(routeDefinition -> routeDefinition.getPredicates().stream()
                        .filter(predicateDefinition -> "Path".equalsIgnoreCase(predicateDefinition.getName()))
                        .forEach(predicateDefinition ->
                                resources.add(swaggerResource(routeDefinition.getId()
                                    , predicateDefinition.getArgs().get(NameUtils.GENERATED_NAME_PREFIX + "0").replace("/**", API_URI)))));
        return resources;
    }

    private SwaggerResource swaggerResource(String name, String location) {
        SwaggerResource swaggerResource = new SwaggerResource();
        swaggerResource.setName(name);
        swaggerResource.setLocation(location);
        swaggerResource.setSwaggerVersion(SWAGGER_VERSION);
        return swaggerResource;
    }
}
