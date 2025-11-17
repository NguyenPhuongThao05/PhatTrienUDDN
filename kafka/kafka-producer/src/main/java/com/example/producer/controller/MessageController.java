package com.example.producer.controller;

import com.example.producer.model.MessageDto;
import com.example.producer.service.MessageProducerService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

@RestController
@RequestMapping("/api/producer")
@CrossOrigin(origins = "*")
public class MessageController {

    @Autowired
    private MessageProducerService messageProducerService;

    private final AtomicLong messageIdGenerator = new AtomicLong(1);

    @PostMapping("/send")
    public ResponseEntity<Map<String, Object>> sendMessage(@Valid @RequestBody MessageDto message) {
        try {
            // Gán ID tự động nếu không có
            if (message.getId() == null) {
                message.setId(messageIdGenerator.getAndIncrement());
            }

            messageProducerService.sendMessage(message);

            Map<String, Object> response = new HashMap<>();
            response.put("status", "success");
            response.put("message", "Message sent to Kafka successfully");
            response.put("messageId", message.getId());
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Failed to send message: " + e.getMessage());
            
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @PostMapping("/send-sync")
    public ResponseEntity<Map<String, Object>> sendMessageSync(@Valid @RequestBody MessageDto message) {
        try {
            if (message.getId() == null) {
                message.setId(messageIdGenerator.getAndIncrement());
            }

            messageProducerService.sendMessageSync(message);

            Map<String, Object> response = new HashMap<>();
            response.put("status", "success");
            response.put("message", "Message sent to Kafka synchronously");
            response.put("messageId", message.getId());
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Failed to send message synchronously: " + e.getMessage());
            
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @PostMapping("/send-batch")
    public ResponseEntity<Map<String, Object>> sendBatchMessages(@RequestParam(defaultValue = "10") int count) {
        try {
            for (int i = 0; i < count; i++) {
                MessageDto message = new MessageDto();
                message.setId(messageIdGenerator.getAndIncrement());
                message.setTitle("Batch Message " + (i + 1));
                message.setContent("This is batch message content number " + (i + 1));
                message.setSender("BatchProducer");
                message.setPriority(i % 3 == 0 ? "HIGH" : "NORMAL");

                messageProducerService.sendMessage(message);
            }

            Map<String, Object> response = new HashMap<>();
            response.put("status", "success");
            response.put("message", "Sent " + count + " messages to Kafka");
            response.put("batchSize", count);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Failed to send batch messages: " + e.getMessage());
            
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "Kafka Producer");
        return ResponseEntity.ok(response);
    }
}