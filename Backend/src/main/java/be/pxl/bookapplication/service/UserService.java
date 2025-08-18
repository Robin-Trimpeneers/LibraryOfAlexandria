package be.pxl.bookapplication.service;

import be.pxl.bookapplication.Exception.EmailAlreadyExistsException;
import be.pxl.bookapplication.domain.User;
import be.pxl.bookapplication.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserService {
    private final UserRepository userRepository;

    private final PasswordEncoder passwordEncoder; // Inject the PasswordEncoder bean

    @Autowired
    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }


    public User RegisterUser(User user) {
        if (userRepository.existsByEmail(user.getEmail())) {
            throw new EmailAlreadyExistsException("Email already exists");
        }
        User newUser = new User(user.getName(), passwordEncoder.encode(user.getPassword()), user.getEmail());
        userRepository.save(newUser);
        return newUser;
    }
}