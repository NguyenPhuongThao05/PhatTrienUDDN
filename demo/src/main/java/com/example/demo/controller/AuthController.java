package com.example.demo.controller;

import com.example.demo.service.TokenService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import java.util.HashMap;
import java.util.Map;

@Controller
public class AuthController {

    @Autowired
    private TokenService tokenService;

    @GetMapping("/")
    public String home() {
        return "index";
    }

    @GetMapping("/profile")
    public String profile(@AuthenticationPrincipal OidcUser principal, Model model) {
        if (principal != null) {
            model.addAttribute("name", principal.getFullName());
            model.addAttribute("email", principal.getEmail());
            model.addAttribute("username", principal.getPreferredUsername());
            model.addAttribute("subject", principal.getSubject());
            model.addAttribute("claims", principal.getClaims());
            model.addAttribute("idToken", principal.getIdToken().getTokenValue());
            model.addAttribute("tokenInfo", tokenService.getTokenInfo());
        }
        return "profile";
    }

    @GetMapping("/api/user")
    @ResponseBody
    public Map<String, Object> user(@AuthenticationPrincipal OidcUser principal) {
        Map<String, Object> userInfo = new HashMap<>();
        if (principal != null) {
            userInfo.put("name", principal.getFullName());
            userInfo.put("email", principal.getEmail());
            userInfo.put("username", principal.getPreferredUsername());
            userInfo.put("subject", principal.getSubject());
            userInfo.put("claims", principal.getClaims());
        }
        return userInfo;
    }

    @GetMapping("/api/token")
    @ResponseBody
    public Map<String, String> token(@AuthenticationPrincipal OidcUser principal) {
        Map<String, String> tokenInfo = new HashMap<>();
        if (principal != null) {
            tokenInfo.put("idToken", principal.getIdToken().getTokenValue());
            tokenInfo.put("issuedAt", principal.getIdToken().getIssuedAt().toString());
            tokenInfo.put("expiresAt", principal.getIdToken().getExpiresAt().toString());
        }
        return tokenInfo;
    }

    @GetMapping("/api/tokens")
    @ResponseBody
    public Map<String, Object> tokens() {
        return tokenService.getTokenInfo();
    }

    @GetMapping("/api/refresh-token")
    @ResponseBody
    public Map<String, Object> refreshToken() {
        Map<String, Object> response = new HashMap<>();
        String refreshToken = tokenService.getRefreshToken();
        response.put("refreshToken", refreshToken);
        response.put("hasRefreshToken", refreshToken != null);
        response.put("isTokenExpired", tokenService.isTokenExpired());
        return response;
    }

    @GetMapping("/login")
    public String login() {
        return "redirect:/oauth2/authorization/keycloak";
    }

    @GetMapping("/logout-keycloak")
    public String logoutKeycloak(HttpServletRequest request) {
        // Clear local session
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        
        // Redirect to KeyCloak logout endpoint
        return "redirect:http://localhost:8180/realms/master/protocol/openid-connect/logout?post_logout_redirect_uri=http://localhost:8080/logout-success";
    }

    @GetMapping("/logout-success")
    public String logoutSuccess(Model model) {
        model.addAttribute("message", "Bạn đã đăng xuất thành công!");
        return "logout-success";
    }

    @GetMapping("/error")
    public String error(Model model) {
        model.addAttribute("message", "Đã có lỗi xảy ra. Vui lòng thử lại.");
        return "error";
    }
}