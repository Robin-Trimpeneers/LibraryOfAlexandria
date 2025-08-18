package be.pxl.bookapplication.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class GoogleBooksService {
    @Value("${google.books.api.url}")
    private String API_URL;

    @Value("${google.books.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public GoogleBooksService(RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    public JsonNode getBook(String ISBN) {
        String url = String.format(API_URL, ISBN, apiKey);
        String jsonResponse = restTemplate.getForObject(url, String.class);

        try {
            return objectMapper.readTree(jsonResponse);
        } catch (Exception e) {
            throw new RuntimeException("Failed to parse JSON response for ISBN: " + ISBN, e);
        }
    }
}