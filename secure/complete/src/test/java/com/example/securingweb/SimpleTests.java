package com.example.securingweb;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
public class SecuringWebApplicationTests {

	@Test
	public void contextLoads() {
		// This test will pass if the application context loads successfully
	}
	
	@Test
	public void applicationStartsUp() {
		// Simple test to verify the application can start
		assert true;
	}
}