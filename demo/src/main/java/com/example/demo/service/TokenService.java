package com.example.demo.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClientService;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
import org.springframework.security.oauth2.core.OAuth2AccessToken;
import org.springframework.security.oauth2.core.OAuth2RefreshToken;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@Service
public class TokenService {

    @Autowired
    private OAuth2AuthorizedClientService authorizedClientService;

    public Map<String, Object> getTokenInfo() {
        Map<String, Object> tokenInfo = new HashMap<>();
        
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof OAuth2AuthenticationToken) {
            OAuth2AuthenticationToken oauthToken = (OAuth2AuthenticationToken) authentication;
            
            OAuth2AuthorizedClient client = authorizedClientService.loadAuthorizedClient(
                oauthToken.getAuthorizedClientRegistrationId(),
                oauthToken.getName()
            );
            
            if (client != null) {
                OAuth2AccessToken accessToken = client.getAccessToken();
                OAuth2RefreshToken refreshToken = client.getRefreshToken();
                
                // Access Token Info
                tokenInfo.put("accessToken", accessToken.getTokenValue());
                tokenInfo.put("accessTokenType", accessToken.getTokenType().getValue());
                tokenInfo.put("accessTokenScopes", accessToken.getScopes());
                tokenInfo.put("accessTokenIssuedAt", accessToken.getIssuedAt());
                tokenInfo.put("accessTokenExpiresAt", accessToken.getExpiresAt());
                
                // Refresh Token Info
                if (refreshToken != null) {
                    tokenInfo.put("refreshToken", refreshToken.getTokenValue());
                    tokenInfo.put("refreshTokenIssuedAt", refreshToken.getIssuedAt());
                    tokenInfo.put("refreshTokenExpiresAt", refreshToken.getExpiresAt());
                    tokenInfo.put("hasRefreshToken", true);
                } else {
                    tokenInfo.put("hasRefreshToken", false);
                }
                
                // Token Status
                tokenInfo.put("isAccessTokenExpired", accessToken.getExpiresAt().isBefore(Instant.now()));
                
                if (refreshToken != null && refreshToken.getExpiresAt() != null) {
                    tokenInfo.put("isRefreshTokenExpired", refreshToken.getExpiresAt().isBefore(Instant.now()));
                }
            }
        }
        
        return tokenInfo;
    }
    
    public boolean isTokenExpired() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof OAuth2AuthenticationToken) {
            OAuth2AuthenticationToken oauthToken = (OAuth2AuthenticationToken) authentication;
            
            OAuth2AuthorizedClient client = authorizedClientService.loadAuthorizedClient(
                oauthToken.getAuthorizedClientRegistrationId(),
                oauthToken.getName()
            );
            
            if (client != null) {
                OAuth2AccessToken accessToken = client.getAccessToken();
                return accessToken.getExpiresAt().isBefore(Instant.now());
            }
        }
        return true;
    }
    
    public String getRefreshToken() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof OAuth2AuthenticationToken) {
            OAuth2AuthenticationToken oauthToken = (OAuth2AuthenticationToken) authentication;
            
            OAuth2AuthorizedClient client = authorizedClientService.loadAuthorizedClient(
                oauthToken.getAuthorizedClientRegistrationId(),
                oauthToken.getName()
            );
            
            if (client != null && client.getRefreshToken() != null) {
                return client.getRefreshToken().getTokenValue();
            }
        }
        return null;
    }
}