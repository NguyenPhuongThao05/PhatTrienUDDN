package com.example.securingweb.bootstrap;

import com.example.securingweb.model.User;
import com.example.securingweb.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.Set;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserService userService;

    @Override
    public void run(String... args) {
        // Create admin user
        User admin = new User();
        admin.setUsername("admin");
        admin.setPassword("admin123");
        admin.setRoles(Set.of("ADMIN"));
        userService.createUser(admin);

        // Create regular user
        User user = new User();
        user.setUsername("user");
        user.setPassword("user123");
        user.setRoles(Set.of("USER"));
        userService.createUser(user);
    }
}
