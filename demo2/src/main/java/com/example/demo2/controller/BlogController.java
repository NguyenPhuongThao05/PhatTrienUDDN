package com.example.demo2.controller;

import com.example.demo2.entity.Blog;
import com.example.demo2.service.BlogService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/blogs")
@RequiredArgsConstructor
public class BlogController {

    private final BlogService blogService;

    @PostMapping
    public ResponseEntity<Blog> createBlog(@RequestBody Blog blog, Authentication authentication) {
        return ResponseEntity.ok(blogService.createBlog(blog, authentication.getName()));
    }

    @GetMapping
    public ResponseEntity<List<Blog>> getAllBlogs() {
        return ResponseEntity.ok(blogService.getAllBlogs());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Blog> getBlogById(@PathVariable Long id) {
        return ResponseEntity.ok(blogService.getBlogById(id));
    }

    @GetMapping("/user")
    public ResponseEntity<List<Blog>> getMyBlogs(Authentication authentication) {
        return ResponseEntity.ok(blogService.getBlogsByUser(authentication.getName()));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Blog> updateBlog(
            @PathVariable Long id,
            @RequestBody Blog blogDetails,
            Authentication authentication) {
        return ResponseEntity.ok(blogService.updateBlog(id, blogDetails, authentication.getName()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteBlog(@PathVariable Long id, Authentication authentication) {
        blogService.deleteBlog(id, authentication.getName());
        return ResponseEntity.ok().build();
    }
}