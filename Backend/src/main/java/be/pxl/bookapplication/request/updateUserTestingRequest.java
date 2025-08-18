package be.pxl.bookapplication.request;

import jakarta.validation.constraints.NotBlank;

public class updateUserTestingRequest {



    private int numberOfBooks;


    public int getNumberOfBooks() {
        return numberOfBooks;
    }
    public void setNumberOfBooks(int numberOfBooks) {
        this.numberOfBooks = numberOfBooks;

    }

}
