package com.example.consumer.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "processed_messages")
public class ProcessedMessage {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long dbId;
    
    @Column(name = "message_id")
    private Long messageId;
    
    @Column(name = "title")
    private String title;
    
    @Column(name = "content", columnDefinition = "TEXT")
    private String content;
    
    @Column(name = "sender")
    private String sender;
    
    @Column(name = "original_timestamp")
    private LocalDateTime originalTimestamp;
    
    @Column(name = "processed_timestamp")
    private LocalDateTime processedTimestamp;
    
    @Column(name = "priority")
    private String priority;
    
    @Column(name = "status")
    private String status = "PROCESSED";

    public ProcessedMessage() {
        this.processedTimestamp = LocalDateTime.now();
    }

    // Getters and Setters
    public Long getDbId() {
        return dbId;
    }

    public void setDbId(Long dbId) {
        this.dbId = dbId;
    }

    public Long getMessageId() {
        return messageId;
    }

    public void setMessageId(Long messageId) {
        this.messageId = messageId;
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

    public LocalDateTime getOriginalTimestamp() {
        return originalTimestamp;
    }

    public void setOriginalTimestamp(LocalDateTime originalTimestamp) {
        this.originalTimestamp = originalTimestamp;
    }

    public LocalDateTime getProcessedTimestamp() {
        return processedTimestamp;
    }

    public void setProcessedTimestamp(LocalDateTime processedTimestamp) {
        this.processedTimestamp = processedTimestamp;
    }

    public String getPriority() {
        return priority;
    }

    public void setPriority(String priority) {
        this.priority = priority;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    @Override
    public String toString() {
        return "ProcessedMessage{" +
                "dbId=" + dbId +
                ", messageId=" + messageId +
                ", title='" + title + '\'' +
                ", sender='" + sender + '\'' +
                ", processedTimestamp=" + processedTimestamp +
                ", priority='" + priority + '\'' +
                ", status='" + status + '\'' +
                '}';
    }
}