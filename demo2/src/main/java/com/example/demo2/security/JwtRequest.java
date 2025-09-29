package com.example.demo2.security;

import lombok.Data;

@Data
public class JwtRequest {
    private String username;
    private String password;
}