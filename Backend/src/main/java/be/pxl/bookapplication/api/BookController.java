package be.pxl.bookapplication.api;

import be.pxl.bookapplication.DTO.BookDTO;
import be.pxl.bookapplication.Exception.NotFoundException;
import be.pxl.bookapplication.domain.Book;
import be.pxl.bookapplication.domain.MyUserPrincipal;
import be.pxl.bookapplication.domain.User;
import be.pxl.bookapplication.domain.UserDetails;
import be.pxl.bookapplication.repository.BookRepository;
import be.pxl.bookapplication.repository.UserDetailsRepository;
import be.pxl.bookapplication.repository.UserRepository;
import be.pxl.bookapplication.request.bookChangesRequest;
import be.pxl.bookapplication.service.BookService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/book")
public class BookController {


    @Autowired
    private BookService bookService;
    @Autowired

    private UserRepository userRepository;
    @Autowired
    private BookRepository bookRepository;

    @Autowired
    private UserDetailsRepository userDetailsRepository;
    private static final Logger log = LoggerFactory.getLogger(BookController.class);


    @GetMapping("/{ISBN}")
    public ResponseEntity<BookDTO> getBookInfo(@AuthenticationPrincipal MyUserPrincipal principal, @PathVariable String ISBN) {

        try {
            Book book = bookService.getBookInformation(ISBN);
            BookDTO bookDTO;
            bookDTO = bookService.mapToDto(book);
            bookDTO.setOwnerId((long) -1);
            return ResponseEntity.ok(bookDTO);
        }catch (Exception e) {
            return ResponseEntity.notFound().build();
        }

    }
    @GetMapping
    public ResponseEntity<List<BookDTO>> GetAllBooksOfPrincipal(@AuthenticationPrincipal MyUserPrincipal principal) {

        try {
            String email = principal.getUsername();

            User user = userRepository.findByEmail(email)
                .orElseThrow(() -> {
                    return new NotFoundException("User not found");
                });
            return ResponseEntity.ok(bookService.getBooksInLibrary(user.getId()));
        }catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }
    @GetMapping("/ISBN/{ISBN}")
    public ResponseEntity<BookDTO> getBookById(@AuthenticationPrincipal MyUserPrincipal principal, @PathVariable String ISBN) {
        try {
            String email = principal.getUsername();

            User user = userRepository.findByEmail(email)
                .orElseThrow(() -> {
                    return new NotFoundException("User not found");
                });
            return ResponseEntity.ok(bookService.getBookByISBNAndOwnerId(ISBN, user.getId()));
        }catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }


    @GetMapping("/categories")
    public ResponseEntity<List<String>> getAllUserCategories(@AuthenticationPrincipal MyUserPrincipal principal) {
        try {
            String email = principal.getUsername();
            User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new NotFoundException("User not found"));
            List<BookDTO> userBooks = bookService.getBooksInLibrary(user.getId());

            List<String> categories = userBooks.stream()
                .map(BookDTO::getGenre)
                .filter(genre -> genre != null && !genre.isEmpty())
                .collect(Collectors.collectingAndThen(
                    Collectors.toMap(
                        String::toLowerCase,
                        genre -> genre,
                        (existing, replacement) -> existing
                    ),
                    map -> new ArrayList<>(map.values())
                ))
                .stream()
                .sorted()
                .collect(Collectors.toList());

            return ResponseEntity.ok(categories);
        } catch (NotFoundException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/category/{category}")
    public ResponseEntity<List<BookDTO>> GetAllBooksOfPrincipalByCategory(
        @AuthenticationPrincipal MyUserPrincipal principal,
        @PathVariable String category
    ) {
        try {
            String email = principal.getUsername();
            User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new NotFoundException("User not found"));

            List<BookDTO> allBooks = bookService.getBooksInLibrary(user.getId());

            // Filter books by category (case-insensitive match)
            List<BookDTO> filteredBooks = allBooks.stream()
                .filter(book ->
                    book.getGenre() != null &&
                        book.getGenre().equalsIgnoreCase(category)
                )
                .toList();

            return ResponseEntity.ok(filteredBooks);

        } catch (NotFoundException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping
    public ResponseEntity<BookDTO> manuallyPostBook(@AuthenticationPrincipal MyUserPrincipal principal, @RequestBody bookChangesRequest request)
    {
        try {
            String email = principal.getUsername();
            User user = userRepository.findByEmail(email).get();
            request.setOwnerid(user.getId());
            bookService.manuallyPostBook(request);
            return ResponseEntity.ok().build();

        } catch (NotFoundException e) {
            log.error("Resource not found: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            log.error("Unexpected error: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    @DeleteMapping("/{ISBN}")
    public ResponseEntity<?> removeBookFromInventory(
        @AuthenticationPrincipal MyUserPrincipal principal,
        @PathVariable String ISBN
    ) {
        try {
            String email = principal.getUsername();
            log.info("Attempting to remove book {} for user {}", ISBN, email);

            // 1. Get authenticated user
            User user = userRepository.findByEmail(email)
                .orElseThrow(() -> {
                    log.error("User not found with email: {}", email);
                    return new NotFoundException("User not found");
                });

            // 2. Get user details
            UserDetails userDetails = userDetailsRepository.findByUserId(user.getId());


            // 3. Find and validate the book belongs to the user
            Book bookToDelete = bookRepository.findByIsbnAndOwnerId(ISBN, userDetails.getId());


            // 4. Remove the book
            bookRepository.delete(bookToDelete);


            userDetailsRepository.save(userDetails);

            log.info("Book {} removed successfully for user {}", ISBN, email);
            return ResponseEntity.ok().build();

        } catch (NotFoundException e) {
            log.error("Delete operation failed: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            log.error("Unexpected error during deletion: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping("/{ISBN}")
    public ResponseEntity<?> putBookInInventory(
        @AuthenticationPrincipal MyUserPrincipal principal,
        @PathVariable String ISBN
    ) {
        try {
            String email = principal.getUsername();
            log.info("Attempting to add book {} for user {}", ISBN, email);

            User user = userRepository.findByEmail(email)
                .orElseThrow(() -> {
                    log.error("User not found with email: {}", email);
                    return new NotFoundException("User not found");
                });

            log.info("Found user: {}", user.getId());

            // 1. Add the book to the library
            bookService.putBookInLibrary(ISBN, user.getId());

            // 2. Update the user's book count

            UserDetails userDetails = userDetailsRepository.findByUserId(user.getId());

            userDetailsRepository.save(userDetails);

            return ResponseEntity.ok().build();

        } catch (NotFoundException e) {
            log.error("Resource not found: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            log.error("Unexpected error: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}
