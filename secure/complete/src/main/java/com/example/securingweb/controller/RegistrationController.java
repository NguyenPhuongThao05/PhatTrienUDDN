package com.example.securingweb.controller;

import com.example.securingweb.dto.UserRegistrationDto;
import com.example.securingweb.model.Role;
import com.example.securingweb.model.User;
import com.example.securingweb.repository.RoleRepository;
import com.example.securingweb.repository.UserRepository;
import com.example.securingweb.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.HashSet;
import java.util.Set;

@Controller
public class RegistrationController {

    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private RoleRepository roleRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Autowired
    private UserService userService;

    @GetMapping("/signup")
    public String showRegistrationForm(Model model) {
        model.addAttribute("user", new UserRegistrationDto());
        return "signup";
    }

    @PostMapping("/signup")
    public String registerUser(@ModelAttribute("user") UserRegistrationDto registrationDto,
                              BindingResult result, 
                              Model model,
                              RedirectAttributes redirectAttributes) {
        
        // Validate input
        if (registrationDto.getUsername() == null || registrationDto.getUsername().trim().isEmpty()) {
            model.addAttribute("error", "Username is required");
            return "signup";
        }
        
        if (registrationDto.getPassword() == null || registrationDto.getPassword().length() < 4) {
            model.addAttribute("error", "Password must be at least 4 characters long");
            return "signup";
        }
        
        if (!registrationDto.getPassword().equals(registrationDto.getConfirmPassword())) {
            model.addAttribute("error", "Passwords do not match");
            return "signup";
        }

        // Check if user already exists
        if (userRepository.findByUsername(registrationDto.getUsername()).isPresent()) {
            model.addAttribute("error", "Username already exists");
            return "signup";
        }

        try {
            // Create new user
            User user = new User();
            user.setUsername(registrationDto.getUsername());
            user.setPassword(registrationDto.getPassword()); // Don't encode here, let UserService do it
            
            // Assign USER role by default
            Set<String> roleNames = new HashSet<>();
            roleNames.add("USER");
            user.setRoles(roleNames);
            
            // Save user using UserService (which handles password encoding)
            userService.createUser(user);
            
            redirectAttributes.addFlashAttribute("message", "Registration successful! Please login.");
            return "redirect:/login";
            
        } catch (Exception e) {
            model.addAttribute("error", "Registration failed: " + e.getMessage());
            return "signup";
        }
    }
}