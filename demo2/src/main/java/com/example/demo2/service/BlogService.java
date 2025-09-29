package com.example.demo2.service;

import com.example.demo2.entity.Blog;
import com.example.demo2.entity.User;
import com.example.demo2.entity.Role;
import com.example.demo2.repository.BlogRepository;
import com.example.demo2.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BlogService {

    private final BlogRepository blogRepository;
    private final UserRepository userRepository;

    public Blog createBlog(Blog blog, String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        blog.setUser(user);
        return blogRepository.save(blog);
    }

    public List<Blog> getAllBlogs() {
        return blogRepository.findAll();
    }

    public Blog getBlogById(Long id) {
        return blogRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Blog not found"));
    }

    public List<Blog> getBlogsByUser(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return blogRepository.findByUser(user);
    }

    public Blog updateBlog(Long id, Blog blogDetails, String username) {
        Blog blog = getBlogById(id);
        User currentUser = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check if the user is the owner of the blog or an ADMIN
        if (!blog.getUser().equals(currentUser) && !currentUser.getRole().equals(Role.ADMIN)) {
            throw new AccessDeniedException("You can only update your own blogs");
        }

        blog.setTitle(blogDetails.getTitle());
        blog.setContent(blogDetails.getContent());
        return blogRepository.save(blog);
    }

    public void deleteBlog(Long id, String username) {
        Blog blog = getBlogById(id);
        User currentUser = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check if the user is the owner of the blog or an ADMIN
        if (!blog.getUser().equals(currentUser) && !currentUser.getRole().equals(Role.ADMIN)) {
            throw new AccessDeniedException("You can only delete your own blogs");
        }

        blogRepository.delete(blog);
    }

    public boolean isOwnerOrAdmin(Long blogId, String username) {
        Blog blog = getBlogById(blogId);
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return blog.getUser().equals(user) || user.getRole() == Role.ADMIN;
    }
}