package com.example.producer.service;

import com.example.producer.model.MessageDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;

import java.util.concurrent.CompletableFuture;

@Service
public class MessageProducerService {

    private static final Logger logger = LoggerFactory.getLogger(MessageProducerService.class);

    @Autowired
    private KafkaTemplate<String, Object> kafkaTemplate;

    @Value("${kafka.topic.message}")
    private String messageTopic;

    public void sendMessage(MessageDto message) {
        try {
            // Sử dụng id làm key để đảm bảo message cùng id đi vào cùng partition
            String key = String.valueOf(message.getId());
            
            CompletableFuture<SendResult<String, Object>> future = kafkaTemplate.send(messageTopic, key, message);
            
            future.thenAccept(result -> {
                logger.info("Message sent successfully to topic {} with key {}, offset: {}", 
                    messageTopic, key, result.getRecordMetadata().offset());
            }).exceptionally(ex -> {
                logger.error("Failed to send message to topic {} with key {}: {}", 
                    messageTopic, key, ex.getMessage());
                return null;
            });
            
        } catch (Exception e) {
            logger.error("Error sending message: {}", e.getMessage(), e);
        }
    }

    public void sendMessageSync(MessageDto message) {
        try {
            String key = String.valueOf(message.getId());
            SendResult<String, Object> result = kafkaTemplate.send(messageTopic, key, message).get();
            logger.info("Message sent synchronously to topic {} with key {}, offset: {}", 
                messageTopic, key, result.getRecordMetadata().offset());
        } catch (Exception e) {
            logger.error("Error sending message synchronously: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to send message", e);
        }
    }
}