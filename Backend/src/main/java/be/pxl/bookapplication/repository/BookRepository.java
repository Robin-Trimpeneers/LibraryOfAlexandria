package be.pxl.bookapplication.repository;

import be.pxl.bookapplication.domain.Book;
import org.springframework.data.jpa.repository.JpaRepository;


import java.util.List;

public interface BookRepository extends JpaRepository<Book, Long> {
    Book findBookByIsbn(String isbn);
    List<Book> findAllBooksByOwnerId(Long ownerId);
    Book findByIsbnAndOwnerId(String isbn, Long ownerId);
}
