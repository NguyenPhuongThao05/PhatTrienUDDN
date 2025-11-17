package com.example.producer.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDateTime;

public class MessageDto {
    
    @JsonProperty("id")
    private Long id;
    
    @JsonProperty("title")
    @NotBlank
    private String title;
    
    @JsonProperty("content")
    @NotBlank
    private String content;
    
    @JsonProperty("sender")
    @NotBlank
    private String sender;
    
    @JsonProperty("timestamp")
    private LocalDateTime timestamp;
    
    @JsonProperty("priority")
    private String priority = "NORMAL";

    public MessageDto() {
        this.timestamp = LocalDateTime.now();
    }

    public MessageDto(Long id, String title, String content, String sender) {
        this.id = id;
        this.title = title;
        this.content = content;
        this.sender = sender;
        this.timestamp = LocalDateTime.now();
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getSender() {
        return sender;
    }

    public void setSender(String sender) {
        this.sender = sender;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    public String getPriority() {
        return priority;
    }

    public void setPriority(String priority) {
        this.priority = priority;
    }

    @Override
    public String toString() {
        return "MessageDto{" +
                "id=" + id +
                ", title='" + title + '\'' +
                ", content='" + content + '\'' +
                ", sender='" + sender + '\'' +
                ", timestamp=" + timestamp +
                ", priority='" + priority + '\'' +
                '}';
    }
}