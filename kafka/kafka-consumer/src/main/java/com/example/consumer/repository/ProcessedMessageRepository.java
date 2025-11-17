package com.example.consumer.repository;

import com.example.consumer.model.ProcessedMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ProcessedMessageRepository extends JpaRepository<ProcessedMessage, Long> {
    
    Optional<ProcessedMessage> findByMessageId(Long messageId);
    
    List<ProcessedMessage> findBySender(String sender);
    
    List<ProcessedMessage> findByPriority(String priority);
    
    List<ProcessedMessage> findByProcessedTimestampBetween(LocalDateTime start, LocalDateTime end);
    
    @Query("SELECT COUNT(p) FROM ProcessedMessage p WHERE p.processedTimestamp >= :since")
    long countProcessedSince(LocalDateTime since);
    
    @Query("SELECT p FROM ProcessedMessage p ORDER BY p.processedTimestamp DESC")
    List<ProcessedMessage> findAllOrderByProcessedTimestamp();
}