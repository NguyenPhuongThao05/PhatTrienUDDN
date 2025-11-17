package com.example.consumer.service;

import com.example.consumer.model.MessageDto;
import com.example.consumer.model.ProcessedMessage;
import com.example.consumer.repository.ProcessedMessageRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class MessageConsumerService {

    private static final Logger logger = LoggerFactory.getLogger(MessageConsumerService.class);

    @Autowired
    private ProcessedMessageRepository repository;

    @KafkaListener(topics = "${kafka.topic.message}", groupId = "${spring.kafka.consumer.group-id}")
    public void consumeMessage(
            @Payload MessageDto message,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset,
            Acknowledgment acknowledgment) {
        
        try {
            logger.info("Received message from topic: {}, partition: {}, offset: {}, message: {}", 
                topic, partition, offset, message);

            // Kiểm tra xem message đã được xử lý chưa (để tránh duplicate processing)
            Optional<ProcessedMessage> existingMessage = repository.findByMessageId(message.getId());
            if (existingMessage.isPresent()) {
                logger.warn("Message with ID {} already processed, skipping...", message.getId());
                acknowledgment.acknowledge();
                return;
            }

            // Xử lý message
            ProcessedMessage processedMessage = processMessage(message);
            
            // Lưu vào database
            repository.save(processedMessage);
            
            logger.info("Successfully processed and saved message with ID: {}", message.getId());
            
            // Acknowledge message sau khi xử lý thành công
            acknowledgment.acknowledge();
            
        } catch (Exception e) {
            logger.error("Error processing message: {}, error: {}", message, e.getMessage(), e);
            // Không acknowledge để message được retry
            throw new RuntimeException("Failed to process message", e);
        }
    }

    private ProcessedMessage processMessage(MessageDto messageDto) {
        // Simulate message processing (có thể thêm business logic ở đây)
        ProcessedMessage processedMessage = new ProcessedMessage();
        processedMessage.setMessageId(messageDto.getId());
        processedMessage.setTitle(messageDto.getTitle());
        processedMessage.setContent(messageDto.getContent());
        processedMessage.setSender(messageDto.getSender());
        processedMessage.setOriginalTimestamp(messageDto.getTimestamp());
        processedMessage.setPriority(messageDto.getPriority());
        processedMessage.setProcessedTimestamp(LocalDateTime.now());
        processedMessage.setStatus("PROCESSED");

        // Simulate processing time for HIGH priority messages
        if ("HIGH".equals(messageDto.getPriority())) {
            try {
                Thread.sleep(100); // Simulate additional processing for high priority
                logger.info("High priority message processed with additional handling");
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }

        return processedMessage;
    }

    public long getProcessedMessageCount() {
        return repository.count();
    }

    public long getRecentProcessedMessageCount(int hours) {
        LocalDateTime since = LocalDateTime.now().minusHours(hours);
        return repository.countProcessedSince(since);
    }
}