package com.example.demo2.repository;

import com.example.demo2.entity.Blog;
import com.example.demo2.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface BlogRepository extends JpaRepository<Blog, Long> {
    List<Blog> findByUser(User user);
}