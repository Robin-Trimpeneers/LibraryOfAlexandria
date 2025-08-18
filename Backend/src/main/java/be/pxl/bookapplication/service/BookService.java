package be.pxl.bookapplication.service;

import be.pxl.bookapplication.DTO.BookDTO;
import be.pxl.bookapplication.domain.Book;
import be.pxl.bookapplication.domain.User;
import be.pxl.bookapplication.domain.UserDetails;
import be.pxl.bookapplication.repository.BookRepository;
import be.pxl.bookapplication.repository.UserDetailsRepository;
import be.pxl.bookapplication.repository.UserRepository;
import be.pxl.bookapplication.request.bookChangesRequest;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class BookService {
    @Autowired
    private BookRepository bookRepository;

   @Autowired
   private UserDetailsRepository userDetailsRepository;
    @Autowired
    private GoogleBooksService googleBooksService;

    public void putBookInLibrary(String ISBN, Long id){
      try {
          Book book = getBookInformation(ISBN);
          book.setOwnerId(id);
          bookRepository.save(book);
      }catch (Exception e){
          throw new RuntimeException(e);
      }

    }

    public List<BookDTO> getBooksInLibrary(long id){
        List<Book>books =  bookRepository.findAllBooksByOwnerId(id);
        List<BookDTO> dtos = new ArrayList<>();
        for (Book book : books) {
            dtos.add(mapToDto(book));
        }
        return dtos;
    }


    public Book getBookInformation(String ISBN) {
        JsonNode jsonNode = googleBooksService.getBook(ISBN);


        if (jsonNode == null || jsonNode.isEmpty()) {
            throw new RuntimeException("No data found for ISBN: " + ISBN);
        }

        Book book = new Book();
        book.setIsbn(ISBN);

        JsonNode volumeInfo = jsonNode.path("items").path(0).path("volumeInfo");

        // Title
        book.setTitle(volumeInfo.has("title") ? volumeInfo.get("title").asText() : "Unknown Title");

        // Author
        if (volumeInfo.has("authors") && volumeInfo.get("authors").isArray() && !volumeInfo.get("authors").isEmpty()) {
            book.setAuthor(volumeInfo.get("authors").get(0).asText());
        } else {
            book.setAuthor("Unknown Author");
        }

        // Genre (from categories)
        if (volumeInfo.has("categories") && volumeInfo.get("categories").isArray() && !volumeInfo.get("categories").isEmpty()) {
            book.setGenre(volumeInfo.get("categories").get(0).asText());
        } else {
            book.setGenre("Unknown Genre");
        }

        // Publisher
        book.setPublisher(volumeInfo.has("publisher") ? volumeInfo.get("publisher").asText() : "Unknown Publisher");

        // Published Date
        book.setPublishedDate(volumeInfo.has("publishedDate") ? volumeInfo.get("publishedDate").asText() : "Unknown Date");

        // Pages (from pageCount)
        if (volumeInfo.has("pageCount")) {
            book.setPages(String.valueOf(volumeInfo.get("pageCount").asInt()));
        } else {
            book.setPages("Unknown");
        }

        // Language
        book.setLanguage(volumeInfo.has("language") ? volumeInfo.get("language").asText() : "Unknown Language");

        // Thumbnail (from imageLinks)
        JsonNode imageLinks = volumeInfo.path("imageLinks");
        if (!imageLinks.isMissingNode() && imageLinks.has("thumbnail")) {
            book.setThumbnail(imageLinks.get("thumbnail").asText());
        } else {
            book.setThumbnail("No thumbnail available");
        }

        // Description
        book.setDescription(volumeInfo.has("description") ? volumeInfo.get("description").asText() : "No description available.");

        // Map Book to BookDTO
        return book;
    }
    public BookDTO getBookByISBNAndOwnerId(String ISBN, Long Ownerid) {
        Book book = bookRepository.findByIsbnAndOwnerId(ISBN,Ownerid);

            BookDTO bookDTO = new BookDTO();
            bookDTO.setIsbn(book.getIsbn());
            bookDTO.setTitle(book.getTitle());
            bookDTO.setAuthor(book.getAuthor());
            bookDTO.setGenre(book.getGenre());
            bookDTO.setPublisher(book.getPublisher());
            bookDTO.setPublishedDate(book.getPublishedDate());
            bookDTO.setLanguage(book.getLanguage());
            bookDTO.setDescription(book.getDescription());
            bookDTO.setPages(book.getPages());
            bookDTO.setThumbnail(book.getThumbnail());
            bookDTO.setOwnerId(book.getOwnerId());
            return bookDTO;


    }

    public BookDTO mapToDto(Book book) {
        BookDTO bookDTO = new BookDTO();
        bookDTO.setIsbn(book.getIsbn());
        bookDTO.setTitle(book.getTitle());
        bookDTO.setAuthor(book.getAuthor());
        bookDTO.setGenre(book.getGenre());
        bookDTO.setPublisher(book.getPublisher());
        bookDTO.setPublishedDate(book.getPublishedDate());
        bookDTO.setPages(book.getPages());
        bookDTO.setLanguage(book.getLanguage());
        bookDTO.setThumbnail(book.getThumbnail());
        bookDTO.setOwnerId(book.getOwnerId());
        bookDTO.setDescription(book.getDescription());
        return bookDTO;
    }

    public void manuallyPostBook(bookChangesRequest request) {
        Book currentBook = new Book();
        currentBook.setTitle(request.getTitle());
        currentBook.setIsbn(request.getIsbn());
        currentBook.setAuthor(request.getAuthor());
        currentBook.setGenre(request.getGenre());
        currentBook.setPublisher(request.getPublisher());
        currentBook.setPublishedDate(request.getPublishedDate());
        currentBook.setPages(request.getPages());
        currentBook.setLanguage(request.getLanguage());
        currentBook.setThumbnail(request.getThumbnail());
        currentBook.setOwnerId(request.getOwnerid());
        currentBook.setDescription(request.getDescription());
        bookRepository.save(currentBook);
    }
}