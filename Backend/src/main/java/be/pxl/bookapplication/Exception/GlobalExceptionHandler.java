package be.pxl.bookapplication.Exception;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // Custom error response record
    public record ErrorResponse(String code, String message) {}

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneralException(Exception ex) {
        return ResponseEntity.internalServerError().body(
            new ErrorResponse("SERVER_ERROR", ex.getMessage()) // Fixed from Error to ErrorResponse
        );
    }

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFoundException(NotFoundException ex) {
        return ResponseEntity.status(404).body(
            new ErrorResponse("NOT_FOUND", ex.getMessage())
        );
    }

    @ExceptionHandler(EmailAlreadyExistsException.class)
    public ResponseEntity<ErrorResponse> handleEmailExists(EmailAlreadyExistsException ex) {
        return ResponseEntity.status(409).body(
            new ErrorResponse("CONFLICT", ex.getMessage())
        );
    }
}