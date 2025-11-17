package com.example.consumer.controller;

import com.example.consumer.model.ProcessedMessage;
import com.example.consumer.repository.ProcessedMessageRepository;
import com.example.consumer.service.MessageConsumerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/consumer")
@CrossOrigin(origins = "*")
public class ConsumerController {

    @Autowired
    private ProcessedMessageRepository repository;

    @Autowired
    private MessageConsumerService consumerService;

    @GetMapping("/messages")
    public ResponseEntity<List<ProcessedMessage>> getAllProcessedMessages() {
        List<ProcessedMessage> messages = repository.findAllOrderByProcessedTimestamp();
        return ResponseEntity.ok(messages);
    }

    @GetMapping("/messages/{messageId}")
    public ResponseEntity<ProcessedMessage> getMessageById(@PathVariable Long messageId) {
        return repository.findByMessageId(messageId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/messages/sender/{sender}")
    public ResponseEntity<List<ProcessedMessage>> getMessagesBySender(@PathVariable String sender) {
        List<ProcessedMessage> messages = repository.findBySender(sender);
        return ResponseEntity.ok(messages);
    }

    @GetMapping("/messages/priority/{priority}")
    public ResponseEntity<List<ProcessedMessage>> getMessagesByPriority(@PathVariable String priority) {
        List<ProcessedMessage> messages = repository.findByPriority(priority);
        return ResponseEntity.ok(messages);
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getConsumerStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalProcessedMessages", consumerService.getProcessedMessageCount());
        stats.put("messagesLastHour", consumerService.getRecentProcessedMessageCount(1));
        stats.put("messagesLast24Hours", consumerService.getRecentProcessedMessageCount(24));
        
        long highPriorityCount = repository.findByPriority("HIGH").size();
        long normalPriorityCount = repository.findByPriority("NORMAL").size();
        
        stats.put("highPriorityMessages", highPriorityCount);
        stats.put("normalPriorityMessages", normalPriorityCount);
        
        return ResponseEntity.ok(stats);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "Kafka Consumer");
        response.put("totalProcessed", String.valueOf(consumerService.getProcessedMessageCount()));
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/messages")
    public ResponseEntity<Map<String, String>> clearAllMessages() {
        long count = repository.count();
        repository.deleteAll();
        
        Map<String, String> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Deleted " + count + " processed messages");
        
        return ResponseEntity.ok(response);
    }
}