package com.aether.borsa;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class BorsaApplication {

	public static void main(String[] args) {
		SpringApplication.run(BorsaApplication.class, args);
	}

}
