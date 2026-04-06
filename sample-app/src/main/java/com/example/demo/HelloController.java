package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.RuntimeMXBean;
import java.util.Map;

@RestController
public class HelloController {

    @GetMapping("/")
    public String hello() {
        return "Hello, World!";
    }

    @GetMapping("/info")
    public Map<String, Object> info() {
        RuntimeMXBean runtime = ManagementFactory.getRuntimeMXBean();
        MemoryMXBean memory = ManagementFactory.getMemoryMXBean();

        return Map.of(
                "jvm", runtime.getVmName() + " " + runtime.getVmVersion(),
                "uptime_ms", runtime.getUptime(),
                "heap_used_mb", memory.getHeapMemoryUsage().getUsed() / (1024 * 1024),
                "heap_max_mb", memory.getHeapMemoryUsage().getMax() / (1024 * 1024),
                "processors", Runtime.getRuntime().availableProcessors(),
                "java_version", System.getProperty("java.version")
        );
    }
}
