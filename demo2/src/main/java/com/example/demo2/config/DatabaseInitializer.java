package com.example.demo2.config;

import com.example.demo2.entity.User;
import com.example.demo2.entity.Role;
import com.example.demo2.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DatabaseInitializer implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        // Create admin account if it doesn't exist
        if (!userRepository.existsByUsername("admin")) {
            User admin = new User();
            admin.setUsername("admin");
            admin.setPassword(passwordEncoder.encode("admin123")); // Default password: admin123
            admin.setRole(Role.ADMIN);
            userRepository.save(admin);
            System.out.println("Admin account created successfully!");
        } else {
            System.out.println("Admin account already exists!");
            // Update admin role to ensure it's correct
            userRepository.findByUsername("admin").ifPresent(admin -> {
                if (!admin.getRole().equals(Role.ADMIN)) {
                    admin.setRole(Role.ADMIN);
                    userRepository.save(admin);
                    System.out.println("Admin role updated!");
                }
            });
        }
    }
}