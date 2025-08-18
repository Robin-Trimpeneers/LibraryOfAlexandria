package be.pxl.bookapplication.domain;


import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

import java.time.LocalDate;
import java.time.Period;
import java.util.ArrayList;
import java.util.List;


    //properties
    @Entity
    public class UserDetails {
        @Id
        @GeneratedValue(strategy = GenerationType.AUTO)
        private long id;

        @OneToOne
        @JoinColumn(name = "user_id")
        private User user;



    //constructors
    public UserDetails() {

    }

    public UserDetails(User user) {
        this.user = user;
    }




    //getters & setter

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }



    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }
}