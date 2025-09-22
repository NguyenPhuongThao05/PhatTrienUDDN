package com.example.securingweb.controller;

import com.example.securingweb.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.security.Principal;

@Controller
@RequestMapping("/admin")
public class AdminController {

    @Autowired
    private UserRepository userRepository;

    @GetMapping
    public String adminPage(Model model, Principal principal) {
        model.addAttribute("users", userRepository.findAll());
        return "admin";
    }
}
