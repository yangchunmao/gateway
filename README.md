# gateway 
> 基于spring cloud gateway实现的示例
- 集成swagger2: http://localhost:9000/swagger-ui.html
- 其他微服务需要集成 Swagger2, 才可显示
- 配置文件中心化管理
- 集成 Sentinel 进行网关限流
   + 在启动参数中，需要添加
   > -Dcsp.sentinel.dashboard=192.168.216.128:8081  -Dproject.name=api-gateway
   > -Dcsp.sentinel.app.type=1
   + 其中 `-Dcsp.sentinel.app.type=1` 是`Spring Cloud Gateway` 接入Sentinel控制台才需要的配置
   
- Spring Cloud Alibaba 默认为 Sentinel 整合了 Servlet、RestTemplate、FeignClient 和 Spring WebFlux。
- Sentinel 在 Spring Cloud 生态中，不仅补全了 Hystrix 在 Servlet 和 RestTemplate 这一块的空白，而且还完全兼容了 Hystrix 在 FeignClient 中限流降级的用法，并且支持运行时灵活地配置和调整限流降级规则。
- 对应这个包
> <dependency>
>      <groupId>com.alibaba.cloud</groupId>
>      <artifactId>spring-cloud-starter-alibaba-sentinel</artifactId>
>  </dependency>
- gateway 只需要网关限流
- 网关作为最外端的应用关口, 是必须的！