package be.pxl.bookapplication.service;

import be.pxl.bookapplication.domain.User;
import be.pxl.bookapplication.domain.UserDetails;
import be.pxl.bookapplication.repository.UserDetailsRepository;
import be.pxl.bookapplication.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.Optional;

@Service
public class UserDetailsService {

    private final UserRepository userRepository;
    private final UserDetailsRepository userDetailsRepository;

    public UserDetailsService(UserRepository userRepository, UserDetailsRepository userDetailsRepository) {
        this.userRepository = userRepository;
        this.userDetailsRepository = userDetailsRepository;
    }

    public void updateUserDetails(long id)
    {
        Optional<User> userOptional = userRepository.findById(id);
        if(userOptional.isPresent()) {
            User user = userOptional.get();
            System.out.println(user);
            UserDetails userDetails = userDetailsRepository.findByUserId(id);
            if (userDetails == null) {
                userDetails = new UserDetails(user);
            }


            userDetailsRepository.save(userDetails);
        }else {
            throw new IllegalArgumentException("User not found");
        }
    }
}
