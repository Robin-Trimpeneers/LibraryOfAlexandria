package be.pxl.bookapplication.request;

import be.pxl.bookapplication.domain.UserDetails;

public class bookChangesRequest {
    private String isbn;
    private String title;
    private String author;
    private String genre; // This maps to the "categories" field in Google Books API
    private String publisher;
    private String publishedDate;
    private String pages;
    private String language;

    private String thumbnail;

    private long ownerid;
    private String description;

    public bookChangesRequest() {
    }

    public bookChangesRequest(String isbn, String title, String author, String genre, String publisher, String publishedDate, String pages, String language, String thumbnail, long ownerid, String description) {
        this.isbn = isbn;
        this.title = title;
        this.author = author;
        this.genre = genre;
        this.publisher = publisher;
        this.publishedDate = publishedDate;
        this.pages = pages;
        this.language = language;
        this.thumbnail = thumbnail;
        this.ownerid = ownerid;
        this.description = description;
    }

    public String getIsbn() {
        return isbn;
    }

    public void setIsbn(String isbn) {
        this.isbn = isbn;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public String getGenre() {
        return genre;
    }

    public void setGenre(String genre) {
        this.genre = genre;
    }

    public String getPublisher() {
        return publisher;
    }

    public void setPublisher(String publisher) {
        this.publisher = publisher;
    }

    public String getPublishedDate() {
        return publishedDate;
    }

    public void setPublishedDate(String publishedDate) {
        this.publishedDate = publishedDate;
    }

    public String getPages() {
        return pages;
    }

    public void setPages(String pages) {
        this.pages = pages;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public String getThumbnail() {
        return thumbnail;
    }

    public void setThumbnail(String thumbnail) {
        this.thumbnail = thumbnail;
    }

    public long getOwnerid() {
        return ownerid;
    }

    public void setOwnerid(long ownerid) {
        this.ownerid = ownerid;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}
