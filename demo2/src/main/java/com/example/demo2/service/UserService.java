package com.example.demo2.service;

import com.example.demo2.entity.User;
import com.example.demo2.entity.Role;
import com.example.demo2.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import java.util.List;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public boolean existsByUsername(String username) {
        return userRepository.existsByUsername(username);
    }

    public User createUser(User user) {
        if (existsByUsername(user.getUsername())) {
            throw new RuntimeException("Username already exists");
        }
        
        if (user.getRole() == null) {
            user.setRole(Role.USER);
        }
        
        return userRepository.save(user);
    }

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public User getUserById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    public User updateUser(Long id, User userDetails, String currentUsername) {
        User user = getUserById(id);
        
        // Only allow users to update their own details unless they are ADMIN
        if (!user.getUsername().equals(currentUsername) && 
            !userRepository.findByUsername(currentUsername).get().getRole().equals(Role.ADMIN)) {
            throw new AccessDeniedException("You can only update your own details");
        }

        user.setUsername(userDetails.getUsername());
        if (userDetails.getPassword() != null && !userDetails.getPassword().isEmpty()) {
            user.setPassword(passwordEncoder.encode(userDetails.getPassword()));
        }
        return userRepository.save(user);
    }

    @PreAuthorize("hasRole('ADMIN')")
    public void deleteUser(Long id, String currentUsername) {
        User currentUser = userRepository.findByUsername(currentUsername)
                .orElseThrow(() -> new RuntimeException("Current user not found"));
        
        if (currentUser.getRole() != Role.ADMIN) {
            throw new AccessDeniedException("Only ADMIN can delete users");
        }
        
        User user = getUserById(id);
        if (user.getRole() == Role.ADMIN) {
            throw new AccessDeniedException("Cannot delete admin user");
        }
        userRepository.delete(user);
    }
}