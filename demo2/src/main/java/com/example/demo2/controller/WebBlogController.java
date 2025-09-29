package com.example.demo2.controller;

import com.example.demo2.entity.Blog;
import com.example.demo2.service.BlogService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/blogs")
@RequiredArgsConstructor
public class WebBlogController {

    private final BlogService blogService;

    @GetMapping
    public String listBlogs(Model model, @AuthenticationPrincipal UserDetails userDetails) {
        // Always show all blogs
        model.addAttribute("blogs", blogService.getAllBlogs());
        // Add the current user's details to the model if they're logged in
        model.addAttribute("currentUser", userDetails);
        return "blogs";
    }

    @GetMapping("/new")
    @PreAuthorize("isAuthenticated()")
    public String showCreateForm(Model model) {
        model.addAttribute("blog", new Blog());
        return "blog-form";
    }

    @PostMapping("/new")
    @PreAuthorize("isAuthenticated()")
    public String createBlog(@ModelAttribute Blog blog, 
                           @AuthenticationPrincipal UserDetails userDetails,
                           RedirectAttributes redirectAttributes) {
        try {
            blogService.createBlog(blog, userDetails.getUsername());
            redirectAttributes.addFlashAttribute("message", "Blog created successfully!");
            return "redirect:/blogs";
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("error", "Error creating blog: " + e.getMessage());
            return "redirect:/blogs/new";
        }
    }

    @GetMapping("/{id}/edit")
    @PreAuthorize("isAuthenticated()")
    public String showEditForm(@PathVariable Long id, Model model) {
        Blog blog = blogService.getBlogById(id);
        model.addAttribute("blog", blog);
        return "blog-form";
    }

    @PostMapping("/{id}/edit")
    @PreAuthorize("isAuthenticated()")
    public String updateBlog(@PathVariable Long id, 
                           @ModelAttribute Blog blog,
                           @AuthenticationPrincipal UserDetails userDetails,
                           RedirectAttributes redirectAttributes) {
        try {
            blogService.updateBlog(id, blog, userDetails.getUsername());
            redirectAttributes.addFlashAttribute("message", "Blog updated successfully!");
            return "redirect:/blogs";
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("error", "Error updating blog: " + e.getMessage());
            return "redirect:/blogs/" + id + "/edit";
        }
    }

    @PostMapping("/{id}/delete")
    @PreAuthorize("isAuthenticated()")
    public String deleteBlog(@PathVariable Long id,
                           @AuthenticationPrincipal UserDetails userDetails,
                           RedirectAttributes redirectAttributes) {
        try {
            blogService.deleteBlog(id, userDetails.getUsername());
            redirectAttributes.addFlashAttribute("message", "Blog deleted successfully!");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("error", "Error deleting blog: " + e.getMessage());
        }
        return "redirect:/blogs";
    }
}