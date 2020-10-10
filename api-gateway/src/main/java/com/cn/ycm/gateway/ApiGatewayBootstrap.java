package com.cn.ycm.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@EnableDiscoveryClient
@SpringBootApplication
public class ApiGatewayBootstrap {

    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayBootstrap.class, args);
    }
}
